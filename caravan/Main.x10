package caravan;

import x10.io.Console;
import x10.util.HashMap;
import x10.glb.GLBParameters;
import x10.glb.GLB;
import x10.util.Pair;
import x10.util.HashMap;
import x10.util.ArrayList;
import x10.util.Timer;
import x10.io.File;
import x10.xrx.Runtime;

import caravan.util.MyLogger;

public class Main {


  public def run( engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcPerBuf: Long ): void {
    val table = new Tables();
    execute( table, engine, saveInterval, timeOut, numProcPerBuf );
  }

  public def restart( dumpFile: String, engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcPerBuf: Long ) {
    val infile = new File( dumpFile );
    val reader = infile.openRead();
    val table = Tables.loadFromBinary( reader );
    execute( table, engine, saveInterval, timeOut, numProcPerBuf );
  }

  private def execute( table: Tables, engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcPerBuf: Long ) {
    if( Place.numPlaces() <= 2 ) {
      Console.ERR.println("NumPlaces: " + Place.numPlaces() );
      throw new Exception("Number of places must be larger than 2");
    }
    if( numProcPerBuf <= 2 ) {
      Console.ERR.println("numProcPerBuf must be 3 or larger since at least two processes are used for producer and buffer");
      throw new Exception("numProcPerBuf must be 3 or larger");
    }
    if( Place.numPlaces() % numProcPerBuf == 1 ) {
      Console.ERR.println("NumPlaces: " + Place.numPlaces() );
      Console.ERR.println("numProcPerBuf: " + numProcPerBuf );
      throw new Exception("NumPlaces % numProcPerBuf cannot be less than 2 since buffer must have at least one buffer and one consumer.");
    }
    val numBuffers = Math.ceil( Place.numPlaces() as Double / numProcPerBuf ) as Long;

    val timer = new Timer();
    val initializationBegin = timer.milliTime();
    val logger = new MyLogger( initializationBegin );
    val refJobProducer = new GlobalRef[JobProducer](
      new JobProducer( table, engine, numBuffers, saveInterval, initializationBegin )
    );
    logger.d("JobProducer has been initialized");

    val jobExecutionBegin = timer.milliTime();

    finish for( i in 0..(numBuffers-1) ) {
      async at( Place(i*numProcPerBuf) ) {
        val min = (here.id == 0) ? 1 : Runtime.hereLong();
        val max = Math.min( min+numProcPerBuf, Place.numPlaces() ) - 1;
        if( here.id < numProcPerBuf ) { logger.d("JobBuffer is being initialized"); }
        val buffer = new JobBuffer( refJobProducer, (max-min), initializationBegin );
        if( here.id < numProcPerBuf ) { logger.d("JobBuffer has been initialized"); }
        buffer.getInitialTasks();
        if( here.id < numProcPerBuf ) { logger.d("JobBuffer got initial tasks"); }
        val refBuffer = new GlobalRef[JobBuffer]( buffer );

        for( j in (min+1)..max ) {
          async at( Place(j) ) {
            if( here.id < numProcPerBuf ) { logger.d("JobConsumer is being initialized"); }
            val consumer = new JobConsumer( refBuffer, initializationBegin );
            if( here.id < numProcPerBuf ) { logger.d("JobConsumer has been initialized"); }
            consumer.setExpiration( initializationBegin + timeOut );
            async {  // must be called in async to realize a better load balancing in all places
              consumer.run();
            }
          }
        }
      }
    }

    val terminationBegin = timer.milliTime();

    at( refJobProducer ) {
      refJobProducer().dumpTables("dump.bin");
    }
    val numUnfinished = table.numUnfinishedRuns();
    if( numUnfinished > 0 ) {
      Console.ERR.println("There are " + numUnfinished + " unfinished tasks.");
    }
    else {
      Console.ERR.println("All the tasks completed.");
    }

    Console.ERR.println("Elapsed times ---");
    Console.ERR.println("  Initialization:" + (jobExecutionBegin-initializationBegin) + " ms");
    Console.ERR.println("  Job Execution :" + (terminationBegin-jobExecutionBegin) + " ms");
    Console.ERR.println("  Termination   :" + (timer.milliTime()-terminationBegin) + " ms");
  }
}
