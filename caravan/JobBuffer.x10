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
  var m_isLockQueueAndFreePlaces: Boolean = false; // lock for m_taskQueue and m_freePlaces
  var m_isLockResults: Boolean = false;

  def this( _refProducer: GlobalRef[JobProducer], _numConsumers: Long, refTimeForLogger: Long ) {
    m_refProducer = _refProducer;
    m_numConsumers = _numConsumers;
    m_logger = new MyLogger( refTimeForLogger );
  }

  private def d(s:String) {
    if( here.id == 1 ) { m_logger.d(s); }
  }

  public def getInitialTasks() {
    when( !m_isLockQueueAndFreePlaces ) { m_isLockQueueAndFreePlaces = true; }
    fillTaskQueue();
    atomic { m_isLockQueueAndFreePlaces = false; }
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
    m_taskQueue.pushLast( tasks );
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
    d("Buffer popTasks is called by " + freePlace);
    when( !m_isLockQueueAndFreePlaces ) { m_isLockQueueAndFreePlaces = true; }

    d("Buffer popTasks is running " + m_numRunning.get() + "/" + m_taskQueue.size() + " called by " + freePlace);

    if( m_taskQueue.size() == 0 && m_freePlaces.isEmpty() ) {
      fillTaskQueue();
    }

    val n = calcNumTasksToPop();
    val tasks = m_taskQueue.popFirst( n );
    m_numRunning.addAndGet( tasks.size );

    if( tasks.size == 0 ) {
      registerFreePlace( freePlace, timeOut );
    }

    d("Buffer sending " + tasks.size + " tasks to consumer " + freePlace );
    atomic { m_isLockQueueAndFreePlaces = false; }

    return tasks;
  }

  private def calcNumTasksToPop(): Long {
    return Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numConsumers)) as Long;
  }

  def saveResults( results: Rail[JobConsumer.RunResult] ) {
    d("Buffer saveResults is called");
    when( !m_isLockResults ) { m_isLockResults = true; }

    d("Buffer saving " + results.size + " results");
    m_resultsBuffer.addAll( results );
    m_numRunning.addAndGet( -results.size );
    if( isReadyToSendResults() ) {
      val resultsToSave: ArrayList[JobConsumer.RunResult] = new ArrayList[JobConsumer.RunResult]();
      for( res in m_resultsBuffer ) {
        resultsToSave.add( res );
      }
      m_resultsBuffer.clear();
      d("Buffer sending " + resultsToSave.size() + "results to Producer");
      val refProd = m_refProducer;
      val bufPlace = here;
      at( refProd ) {
        refProd().saveResults( resultsToSave, bufPlace );
      }
      d("Buffer sent " + resultsToSave.size() + "results to Producer");
    }
    atomic { m_isLockResults = false; }

    d("Buffer saved " + results.size + " results");
  }

  private def isReadyToSendResults(): Boolean {
    // to finalize the program,
    // we have to send results whenever all tasks have finished.
    var qSize: Long;
    atomic { qSize = m_taskQueue.size(); }
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
    when( !m_isLockQueueAndFreePlaces ) { m_isLockQueueAndFreePlaces = true; }
    d("Buffer filling queue");
    fillTaskQueue();
    d("Buffer filled queue");
    d("Buffer launching consumers");
    launchConsumerAtFreePlace();
    d("Buffer launched consumers");
    atomic{ m_isLockQueueAndFreePlaces = false; }
  }

  private def launchConsumerAtFreePlace() {
    val refMe = new GlobalRef[JobBuffer]( this );
    for( pair in m_freePlaces ) {
      val place = pair.first;
      val timeOut = pair.second;
      at( place ) async {
        val consumer = new JobConsumer( refMe, m_logger.m_refTime );
        consumer.setExpiration( timeOut );
        consumer.run();
      }
    }
    m_freePlaces.clear(); // must be cleared since consumers are launched
  }
}

