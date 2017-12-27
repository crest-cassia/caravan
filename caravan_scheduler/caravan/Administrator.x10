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

public class Administrator {

  val m_timer: Timer;
  val m_logger: Logger;
  val m_initializationBegin: Long;

  def this() {
    m_timer = new Timer();
    m_initializationBegin = m_timer.milliTime();
    m_logger = new Logger( m_initializationBegin );
  }

  private def checkNumPlaces( numProcPerBuf: Long ) {
    if( Place.numPlaces() <= 2 ) {
      m_logger.e("NumPlaces: " + Place.numPlaces() );
      throw new Exception("Number of places must be larger than 2");
    }
    if( numProcPerBuf <= 2 ) {
      m_logger.e("numProcPerBuf must be 3 or larger since at least two processes are used for producer and buffer");
      throw new Exception("numProcPerBuf must be 3 or larger");
    }
    if( Place.numPlaces() % numProcPerBuf == 1 ) {
      m_logger.e("NumPlaces: " + Place.numPlaces() );
      m_logger.e("numProcPerBuf: " + numProcPerBuf );
      throw new Exception("NumPlaces % numProcPerBuf cannot be less than 2 since buffer must have at least one buffer and one consumer.");
    }
  }

  public def run( cmd_args: Rail[String], timeOut: Long, numProcPerBuf: Long ) {
    checkNumPlaces( numProcPerBuf );

    val numBuffers = Math.ceil( Place.numPlaces() as Double / numProcPerBuf ) as Long;
    val jobExecutionBegin: Long;
    val terminationBegin: Long;
    val refJobProducer = new GlobalRef[JobProducer](
      new JobProducer( numBuffers, m_initializationBegin )
    );
    at(refJobProducer ) { refJobProducer().launchSearcher(cmd_args); }
    try {
      m_logger.i("Starting CARAVAN");
      at( refJobProducer ) { refJobProducer().enqueueInitialTasks(); }
      m_logger.d("JobProducer has been initialized");

      jobExecutionBegin = m_timer.milliTime();

      finish for( i in 0..(numBuffers-1) ) {
        val bufPlace = (i==0) ? 1 : i*numProcPerBuf;
        at( Place(bufPlace) ) async {
          val minConsPlace = here.id+1;
          val maxConsPlace = Math.min( (i+1)*numProcPerBuf, Place.numPlaces() ) - 1;
          if( i==0 ) { m_logger.d("JobBuffer is being initialized"); }
          val buffer = new JobBuffer( refJobProducer, (maxConsPlace-minConsPlace+1), m_initializationBegin );
          if( i==0 ) { m_logger.d("JobBuffer has been initialized"); }

          val consumerPlaceTimeoutPairs = new ArrayList[ Pair[Place,Long] ]();
          for( j in minConsPlace..maxConsPlace ) {
            val place = Place(j);
            val t = m_initializationBegin + timeOut;
            consumerPlaceTimeoutPairs.add( Pair[Place,Long]( place, t ) );
          }
          buffer.registerConsumerPlaces( consumerPlaceTimeoutPairs );
          if( i==0 ) { m_logger.d("JobConsumers are registered to Buffer"); }
          buffer.getInitialTasks();
        }
      }

      terminationBegin = m_timer.milliTime();

      at( refJobProducer ) {
        refJobProducer().terminateSearcher();
        val numUnfinished = refJobProducer().numUnfinished();
        if( numUnfinished > 0 ) {
          m_logger.e("There are " + numUnfinished + " unfinished tasks.");
        }
        else {
          m_logger.i("All tasks completed.");
        }
        refJobProducer().dumpResults("tasks.bin");
      }
    }
    finally {
      at( refJobProducer ) { refJobProducer().waitSearcher(); }
    }

    m_logger.i("Elapsed times ---");
    m_logger.i("  Initialization:" + (jobExecutionBegin-m_initializationBegin) + " ms");
    m_logger.i("  Job Execution :" + (terminationBegin-jobExecutionBegin) + " ms");
    m_logger.i("  Termination   :" + (m_timer.milliTime()-terminationBegin) + " ms");
  }
}
