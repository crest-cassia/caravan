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

public class Main {

  public def run( engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcBerBuf: Long ): void {
    val table = new Tables();
    execute( table, engine, saveInterval, timeOut, numProcBerBuf );
  }

  public def restart( dumpFile: String, engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcBerBuf: Long ) {
    val infile = new File( dumpFile );
    val reader = infile.openRead();
    val table = Tables.loadFromBinary( reader );
    execute( table, engine, saveInterval, timeOut, numProcBerBuf );
  }

  private def execute( table: Tables, engine: SearchEngineI, saveInterval: Long, timeOut: Long, numProcPerBuf: Long ) {
    if( Place.numPlaces() == 1 ) {
      Console.ERR.println("NumPlaces: " + Place.numPlaces() );
      throw new Exception("Number of places must be larger than 1");
    }
    if( Place.numPlaces() % numProcPerBuf == 1 ) {
      Console.ERR.println("NumPlaces: " + Place.numPlaces() );
      Console.ERR.println("numProcPerBuf: " + numProcPerBuf );
      throw new Exception("NumPlaces % numProcPerBuf cannot be 1 since buffer must have at least one consumer.");
    }
    val numBuffers = Math.ceil( Place.numPlaces() as Double / numProcPerBuf ) as Long;

    val timer = new Timer();
    val initializationBegin = timer.milliTime();
    val refJobProducer = new GlobalRef[JobProducer](
      new JobProducer( new Tables(), engine, numBuffers, saveInterval )
    );
    val jobExecutionBegin = timer.milliTime();

    finish for( i in 0..(numBuffers-1) ) {
      async at( Place(i*numProcPerBuf) ) {
        val min = Runtime.hereLong();
        val max = Math.min( min+numProcPerBuf, Place.numPlaces() );
        val buffer = new JobBuffer( refJobProducer, (max-1-min) );
        buffer.getInitialTasks();
        val refBuffer = new GlobalRef[JobBuffer]( buffer );

        for( j in (min+1)..(max-1) ) {
          async at( Place(j) ) {
            val consumer = new JobConsumer( refBuffer );
            consumer.setExpiration( timeOut );
            consumer.run();
          }
        }
      }
    }

    val terminationBegin = timer.milliTime();

    at( refJobProducer ) {
      refJobProducer().dumpTables("dump.bin");
    }

    Console.ERR.println("Elapsed times ---");
    Console.ERR.println("  Initialization:" + (jobExecutionBegin-initializationBegin) + " ms");
    Console.ERR.println("  Job Execution :" + (terminationBegin-jobExecutionBegin) + " ms");
    Console.ERR.println("  Termination   :" + (timer.milliTime()-terminationBegin) + " ms");
  }
}
