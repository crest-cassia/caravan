package caravan;

import x10.util.ArrayList;
import x10.util.Pair;
import x10.util.Timer;
import x10.util.concurrent.AtomicLong;
import x10.util.concurrent.AtomicBoolean;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobBuffer {

  val m_refProducer: GlobalRef[JobProducer];
  val m_logger: MyLogger;
  val m_taskQueue = new Deque[Task]();
  val m_resultsBuffer = new ArrayList[JobConsumer.RunResult]();
  var m_numRunning: AtomicLong = new AtomicLong(0);
  val m_freePlaces = new ArrayList[ Pair[Place,Long] ]();
  val m_numConsumers: Long;  // number of consumers belonging to this buffer
  val m_isSendingResults: AtomicBoolean = new AtomicBoolean(false);

  def this( _refProducer: GlobalRef[JobProducer], _numConsumers: Long, refTimeForLogger: Long ) {
    m_refProducer = _refProducer;
    m_numConsumers = _numConsumers;
    m_logger = new MyLogger( refTimeForLogger );
  }

  private def d(s:String) {
    if( here.id == 1 ) { m_logger.d(s); }
  }

  public def getInitialTasks() {
    fillTaskQueue();
    launchConsumerAtFreePlace();
  }

  public def registerConsumerPlaces(placeTimeoutPairs: ArrayList[ Pair[Place,Long] ]) {
    atomic {
      for( pair in placeTimeoutPairs ) {
        m_freePlaces.add( pair );
      }
    }
  }

  private def fillTaskQueue(): void {
    d("Buffer getting tasks from producer");
    val refProd = m_refProducer;
    val refBuf = new GlobalRef[JobBuffer]( this );
    val numCons = m_numConsumers;
    val tasks = at( refProd ) {
      return refProd().popTasksOrRegisterFreeBuffer( refBuf, numCons );
    };
    d("Buffer got " + tasks.size + " tasks from producer");
    atomic {
      m_taskQueue.pushLast( tasks );
    }
    /*
    @Pragma(Pragma.FINISH_HERE) finish at( refProd ) async {
      val tasks = refProd().popTasksOrRegisterFreeBuffer( refBuf, numCons );
      at( refBuf ) async {
        refBuf().d("Buffer got " + tasks.size + " tasks from producer");
        refBuf().m_taskQueue.pushLast( tasks );
      }
    }
    */
  }

  // return tasks
  // if there is no tasks to return, register consumer as free place
  def popTasksOrRegisterFreePlace( freePlace: Place, timeOut: Long ): Rail[Task] {
    var needToFillTask: Boolean = false;
    d("Buffer popTasks is called by " + freePlace);

    val tasks: Rail[Task];
    atomic {
      val n = calcNumTasksToPop();
      tasks = m_taskQueue.popFirst( n );
      m_numRunning.addAndGet( tasks.size );

      if( tasks.size == 0 ) {
        if( m_freePlaces.isEmpty() ) {
          needToFillTask = true;  // true only for the first consumer which retrieved no task
        }
        registerFreePlace( freePlace, timeOut );
      }

      d("Buffer is sending " + tasks.size + " tasks to consumer " + freePlace );
    }

    if( needToFillTask ) {
      async {
        fillTaskQueue();
        launchConsumerAtFreePlace();
      }
    }
    return tasks;
  }

  private def calcNumTasksToPop(): Long {
    return Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numConsumers)) as Long;
  }

  def saveResults( results: Rail[JobConsumer.RunResult] ) {
    d("Buffer is saving " + results.size + " results");
    val resultsToSave: ArrayList[JobConsumer.RunResult] = new ArrayList[JobConsumer.RunResult]();
    atomic {
      m_resultsBuffer.addAll( results );
      m_numRunning.addAndGet( -results.size );
      if( isReadyToSendResults() && m_isSendingResults.get() == false ) {
        for( res in m_resultsBuffer ) {
          resultsToSave.add( res );
        }
        m_resultsBuffer.clear();
        m_isSendingResults.set(true);  // avoid sending results from multiple activities
      }
    }

    if( resultsToSave.size() > 0 ) {
      sendResultsToProducer( resultsToSave );
    }

    d("Buffer has saved " + results.size + " results");
  }

  private def sendResultsToProducer( results: ArrayList[JobConsumer.RunResult] ) {
    d("Buffer is sending " + results.size() + " results to Producer");
    val refProd = m_refProducer;
    val bufPlace = here;
    async {
      at( refProd ) {
        refProd().saveResults( results, bufPlace );
      }
      m_isSendingResults.set(false);  // Producer is ready to receive other results
      d("Buffer has sent " + results.size() + " results to Producer");
    }
  }

  private def isReadyToSendResults(): Boolean {
    // to finalize the program,
    // we have to send results whenever all tasks have finished.
    var qSize: Long;
    qSize = m_taskQueue.size();
    if( m_numRunning.get() + qSize == 0 ) { return true; }

    // depending on the size of results, we determine whether send or not.
    val size = m_resultsBuffer.size();

    // send results if size is larger than the maximum capacity (m_numConsumers)
    if( size >= m_numConsumers ) { return true; }

    val minimumBulkSize = m_numConsumers * 0.2;
    if( size >= m_numRunning.get() + qSize && size >= minimumBulkSize ) {
      return true;
    }
    else {
      return false;
    }
  }

  private def registerFreePlace( freePlace: Place, timeOut: Long ) {
    d("Buffer registering free consumer " + freePlace );
    m_freePlaces.add( Pair[Place,Long](freePlace, timeOut) );
    d("Buffer registered free consumer " + freePlace );
  }

  def wakeUp() {
    d("Buffer waking up");
    fillTaskQueue();
    launchConsumerAtFreePlace();
  }

  private def launchConsumerAtFreePlace() {
    val refMe = new GlobalRef[JobBuffer]( this );
    val consumerPlaces: ArrayList[ Pair[Place,Long] ];
    atomic {
      if( m_taskQueue.size() == 0 ) { return; }
      consumerPlaces = m_freePlaces.clone();
      m_freePlaces.clear();
    }
    for( pair in consumerPlaces ) {
      val place = pair.first;
      val timeOut = pair.second;
      d("Buffer launching consumers at " + place);
      at( place ) async {
        val consumer = new JobConsumer( refMe, m_logger.m_refTime );
        consumer.setExpiration( timeOut );
        consumer.run();
      }
    }
    d("Buffer launched all free consumers");
  }
}

