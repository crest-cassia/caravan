package caravan;

import x10.compiler.*;
import x10.util.ArrayList;
import x10.util.HashMap;
import x10.io.File;
import x10.util.Timer;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobProducer {

  val m_engine: SearchEngineI;
  val m_taskQueue: Deque[Task];
  val m_freeBuffers: HashMap[Place, GlobalRef[JobBuffer]];
  val m_numBuffers: Long;
  val m_timer = new Timer();
  var m_lastSavedAt: Long;
  val m_saveInterval: Long;
  val m_refTimeForLogger: Long;
  var m_dumpFileIndex: Long;
  val m_logger: MyLogger;

  def this( _numBuffers: Long, _refTimeForLogger: Long ) {
    m_logger = new MyLogger( _refTimeForLogger );
    m_taskQueue = new Deque[Task]();
    enqueueInitialTasks();
    if( m_taskQueue.empty() ) {
      Console.ERR.println("[E] No task was created when initializing JobProducer");
      throw new Exception("no task to execute");
    }
    m_freeBuffers = new HashMap[Place, GlobalRef[JobBuffer]]();
    m_numBuffers = _numBuffers;
    m_lastSavedAt = m_timer.milliTime();
    m_saveInterval = _saveInterval;
    m_refTimeForLogger = _refTimeForLogger;
    m_dumpFileIndex = 0;
  }

  private def d(s:String) {
    m_logger.d(s);
  }

  private def enqueueInitialTasks() {
    // IMPLEMENT ME
    val tasks = m_engine.createInitialTask( m_tables, Simulator.searchRegion() );
    m_taskQueue.pushLast( tasks.toRail() );
  }

  private def registerFreeBuffer( refBuffer: GlobalRef[JobBuffer] ) {
    d("Producer registering free buffer : " + refBuffer.home );
    m_freeBuffers( refBuffer.home )= refBuffer; // to avoid duplication, we use HashMap
    d("Producer registered free buffer : " + refBuffer.home );
  }

  public def saveResults( results: ArrayList[JobConsumer.RunResult], caller: Place ) {
    d("Producer saveResults is called. " + results.size() + " results sent by " + caller);

    val refBuffers = new ArrayList[GlobalRef[JobBuffer]]();
    atomic {
      var tasks: ArrayList[Task] = new ArrayList[Task]();
      for( res in results ) {
        // IMPLEMENT ME
        sendResultToSearcher(res.runid, res.result, res.placeId, res.startAt - m_refTimeForLogger, res.finishAt - m_refTimeForLogger);
        // run.storeResult( res.result, res.placeId, res.startAt - m_refTimeForLogger, res.finishAt - m_refTimeForLogger );
        val local_tasks = getTasks();
        for( task in local_tasks ) {
          tasks.add( task );
        }
      }
      d("Producer saved " + results.size() + " results sent by " + caller);

      if( tasks.size() > 0 ) {
        m_taskQueue.pushLast( tasks.toRail() );
        if( m_freeBuffers.size() > 0 ) {
          val popped = popFreeBuffers( m_taskQueue.size() );
          for( ref in popped ) { refBuffers.add( ref ); }
        }
      }
    }

    if( refBuffers.size() > 0 ) {
      async {
        for( refBuf in refBuffers ) {
          at( refBuf ) async {
            refBuf().wakeUp();
          }
        }
        d("Producer has woken up " + refBuffers.size() + " free buffers");
      }
    }
  }

  private def popFreeBuffers(numBuffersToLaunch: Long): ArrayList[GlobalRef[JobBuffer]] {

    val refBuffers = new ArrayList[GlobalRef[JobBuffer]]();
    for( entry in m_freeBuffers.entries() ) {
      val refBuf = entry.getValue();
      refBuffers.add( refBuf );
      if( refBuffers.size() >= numBuffersToLaunch ) { break; }
    }
    for( refBuf in refBuffers ) {
      m_freeBuffers.delete( refBuf.home );
    }
    return refBuffers;
  }

  // return tasks if available.
  // if there is no task, register the buffer as free
  public atomic def popTasksOrRegisterFreeBuffer( refBuf: GlobalRef[JobBuffer], numConsOfBuffer: Long ): Rail[Task] {
    d("Producer popTasks is called by " + refBuf.home);
    val n = calcNumTasksToPop( numConsOfBuffer );
    val tasks = m_taskQueue.popFirst( n );

    if( tasks.size == 0 ) {
      registerFreeBuffer( refBuf );
    }
    d("Producer sending " + tasks.size + " tasks to buffer" + refBuf.home);
    return tasks;
  }

  private def calcNumTasksToPop( numConsOfBuffer: Long ): Long {
    var target:Long = (Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numBuffers)) as Long);
    val min = Math.ceil( numConsOfBuffer * 0.2 ) as Long;
    if( target < min ) {
      target = min;
    }
    if( target > m_taskQueue.size() ) {
      target = m_taskQueue.size();
    }
    return target;
  }
}

