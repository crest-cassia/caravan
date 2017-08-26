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
import x10.compiler.*;

import caravan.util.MyLogger;

public class Administrator {

  private def checkNumPlaces( numProcPerBuf: Long ) {
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
  }

  public def run( timeOut: Long, numProcPerBuf: Long ) {
    checkNumPlaces( numProcPerBuf );

    val numBuffers = Math.ceil( Place.numPlaces() as Double / numProcPerBuf ) as Long;
    val timer = new Timer();
    val initializationBegin = timer.milliTime();
    val logger = new MyLogger( initializationBegin );
    val refJobProducer = new GlobalRef[JobProducer](
      new JobProducer( numBuffers, initializationBegin )
    );
    logger.d("JobProducer has been initialized");

    val jobExecutionBegin = timer.milliTime();

    finish for( i in 0..(numBuffers-1) ) {
      val bufPlace = (i==0) ? 1 : i*numProcPerBuf;
      at( Place(bufPlace) ) async {
        val minConsPlace = here.id+1;
        val maxConsPlace = Math.min( (i+1)*numProcPerBuf, Place.numPlaces() ) - 1;
        if( i==0 ) { logger.d("JobBuffer is being initialized"); }
        val buffer = new JobBuffer( refJobProducer, (maxConsPlace-minConsPlace+1), initializationBegin );
        if( i==0 ) { logger.d("JobBuffer has been initialized"); }

        val consumerPlaceTimeoutPairs = new ArrayList[ Pair[Place,Long] ]();
        for( j in minConsPlace..maxConsPlace ) {
          val place = Place(j);
          val t = initializationBegin + timeOut;
          consumerPlaceTimeoutPairs.add( Pair[Place,Long]( place, t ) );
        }
        buffer.registerConsumerPlaces( consumerPlaceTimeoutPairs );
        if( i==0 ) { logger.d("JobConsumers are registered to Buffer"); }
        buffer.getInitialTasks();
      }
    }

    val terminationBegin = timer.milliTime();

    at( refJobProducer ) {
      val numUnfinished = refJobProducer().numUnfinished();
      if( numUnfinished > 0 ) {
        Console.ERR.println("There are " + numUnfinished + " unfinished tasks.");
      }
      else {
        Console.ERR.println("All the tasks completed.");
      }
    }

    Console.ERR.println("Elapsed times ---");
    Console.ERR.println("  Initialization:" + (jobExecutionBegin-initializationBegin) + " ms");
    Console.ERR.println("  Job Execution :" + (terminationBegin-jobExecutionBegin) + " ms");
    Console.ERR.println("  Termination   :" + (timer.milliTime()-terminationBegin) + " ms");
  }
}
