package caravan;

import x10.util.ArrayList;
import x10.util.Timer;
import x10.util.concurrent.AtomicBoolean;
import caravan.util.MyLogger;

class JobBuffer {

  val m_refProducer: GlobalRef[JobProducer];
  val m_logger = new MyLogger();
  val m_taskQueue = new ArrayList[Task]();
  val m_resultsBuffer = new ArrayList[JobConsumer.RunResult]();
  var m_numRunning: Long = 0;
  val m_freePlaces = new ArrayList[Place]();
  val m_numConsumers: Long;  // number of consumers belonging to this buffer
  val m_isLockQueue: AtomicBoolean = new AtomicBoolean(false);
  val m_isLockResults: AtomicBoolean = new AtomicBoolean(false);
  val m_isLockFreePlaces: AtomicBoolean = new AtomicBoolean(false);

  def this( _refProducer: GlobalRef[JobProducer], _numConsumers: Long ) {
    m_refProducer = _refProducer;
    m_numConsumers = _numConsumers;
  }

  private def d(s:String) {
    if( here.id == 0 ) { m_logger.d(s); }
  }

  public def getInitialTasks() {
    when( !m_isLockQueue.get() ) { m_isLockQueue.set(true); }
    fillTaskQueueIfEmpty();
    m_isLockQueue.set(false);
  }

  private def fillTaskQueueIfEmpty(): void {
    if( m_taskQueue.size() == 0 ) {
      d("Buffer getting tasks from producer");
      val refProd = m_refProducer;
      val tasks = at( refProd ) {
        return refProd().popTasks();
      };
      d("Buffer got " + tasks.size() + " tasks from producer");
      for( task in tasks ) {
        m_taskQueue.add( task );
      }
    }
  }

  def popTasks(): ArrayList[Task] {
    when( !m_isLockQueue.get() ) { m_isLockQueue.set(true); }
    d("Buffer popTasks " + m_numRunning + "/" + m_taskQueue.size() );
    val tasks = new ArrayList[Task]();
    fillTaskQueueIfEmpty();

    val n = calcNumTasksToPop();
    for( i in 1..n ) {
      if( m_taskQueue.size() == 0 ) {
        break;
      }
      val task = m_taskQueue.removeFirst();
      tasks.add( task );
      m_numRunning += 1;
    }

    d("Buffer sending " + tasks.size() + " tasks to consumer" );
    m_isLockQueue.set(false);
    return tasks;
  }

  private def calcNumTasksToPop(): Long {
    return Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numConsumers)) as Long;
  }

  def saveResult( result: JobConsumer.RunResult ) {
    when( !m_isLockResults.get() ) { m_isLockResults.set(true); }
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
    m_isLockResults.set(false);

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
    return (m_resultsBuffer.size() >= m_numRunning  + m_taskQueue.size() );
  }

  def registerFreePlace( freePlace: Place ) {
    when( !m_isLockFreePlaces.get() ) { m_isLockFreePlaces.set(true); }
    d("Buffer registering freePlace " + freePlace );
    var registerToProducer: Boolean = false;
    if( m_freePlaces.isEmpty() ) {
      registerToProducer = true;
    }
    m_freePlaces.add( freePlace );

    if( registerToProducer ) {
      d("Buffer registering self as free buffer");
      val refMe = new GlobalRef[JobBuffer]( this );
      val refProd = m_refProducer;
      at( refProd ) {
        refProd().registerFreeBuffer( refMe );
      }
      d("Buffer registered self as free buffer");
    }
    d("Buffer registered freePlace " + freePlace );
    m_isLockFreePlaces.set(false);
  }

  def wakeUp() {
    d("Buffer waking up");
    when( !m_isLockQueue.get() ) { m_isLockQueue.set(true); }
    d("Buffer filling queue");
    fillTaskQueueIfEmpty();
    d("Buffer filled queue");
    m_isLockQueue.set(false);
    when( !m_isLockFreePlaces.get() ) { m_isLockFreePlaces.set(true); }
    d("Buffer launching consumers");
    launchConsumerAtFreePlace();
    d("Buffer launched consumers");
    m_isLockFreePlaces.set(false);
  }

  private def launchConsumerAtFreePlace() {
    val freePlaces = new ArrayList[Place]();
    for( place in m_freePlaces ) {
      freePlaces.add( place );
    }
    m_freePlaces.clear();

    val refMe = new GlobalRef[JobBuffer]( this );
    for( place in freePlaces ) {
      async at( place ) {
        val consumer = new JobConsumer( refMe );
        consumer.run();
      }
    }
  }
}

