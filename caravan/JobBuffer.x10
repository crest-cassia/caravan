package caravan;

import x10.util.ArrayList;
import x10.util.Pair;
import x10.util.Timer;
import x10.util.concurrent.AtomicBoolean;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobBuffer {

  val m_refProducer: GlobalRef[JobProducer];
  val m_logger: MyLogger;
  val m_taskQueue = new Deque[Task]();
  val m_resultsBuffer = new ArrayList[JobConsumer.RunResult]();
  var m_numRunning: Long = 0;
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
    val tasks = at( refProd ) {
      return refProd().popTasksOrRegisterFreeBuffer( refBuf );
    };
    d("Buffer got " + tasks.size + " tasks from producer");
    m_taskQueue.pushLast( tasks );
  }

  // return tasks
  // if there is no tasks to return, register consumer as free place
  def popTasksOrRegisterFreePlace( freePlace: Place, timeOut: Long ): Rail[Task] {
    when( !m_isLockQueueAndFreePlaces ) { m_isLockQueueAndFreePlaces = true; }

    d("Buffer popTasks " + m_numRunning + "/" + m_taskQueue.size() );

    if( m_taskQueue.size() == 0 && m_freePlaces.isEmpty() ) {
      fillTaskQueue();
    }

    val n = calcNumTasksToPop();
    val tasks = m_taskQueue.popFirst( n );
    m_numRunning += tasks.size;

    if( tasks.size == 0 ) {
      registerFreePlace( freePlace, timeOut );
    }

    d("Buffer sending " + tasks.size + " tasks to consumer" );
    atomic { m_isLockQueueAndFreePlaces = false; }

    return tasks;
  }

  private def calcNumTasksToPop(): Long {
    return Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numConsumers)) as Long;
  }

  def saveResult( result: JobConsumer.RunResult ) {
    when( !m_isLockResults ) { m_isLockResults = true; }
    val resultsToSave: ArrayList[JobConsumer.RunResult] = new ArrayList[JobConsumer.RunResult]();

    d("Buffer saving result of task " + result.runId );
    m_resultsBuffer.add( result );
    m_numRunning -= 1;
    if( hasEnoughResults() ) { // TODO: set parameter
      for( res in m_resultsBuffer ) {
        resultsToSave.add( res );
      }
      m_resultsBuffer.clear();
    }
    atomic { m_isLockResults = false; }

    if( resultsToSave.size() > 0 ) {
      d("Buffer sending " + resultsToSave.size() + "results to Producer");
      val refProd = m_refProducer;
      at( refProd ) {
        refProd().saveResults( resultsToSave );
      }
      d("Buffer sent " + resultsToSave.size() + "results to Producer");
    }
    d("Buffer saved result of task " + result.runId);
  }

  private def hasEnoughResults(): Boolean {
    val size = m_resultsBuffer.size();
    return (size >= m_numConsumers) || (size >= m_numRunning + m_taskQueue.size() );
  }

  private def registerFreePlace( freePlace: Place, timeOut: Long ) {
    d("Buffer registering free consumer " + freePlace );
    var registerToProducer: Boolean = false;
    if( m_freePlaces.isEmpty() ) {
      registerToProducer = true;
    }
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
      async at( place ) {
        val consumer = new JobConsumer( refMe, m_logger.m_refTime );
        consumer.setExpiration( timeOut );
        async {   // must be called in async to realize a better load balancing in all places
          consumer.run();
        }
      }
    }
    m_freePlaces.clear(); // must be cleared since consumers are launched
  }
}

