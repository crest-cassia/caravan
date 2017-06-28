package caravan;

import x10.compiler.*;
import x10.util.ArrayList;
import x10.util.HashMap;
import x10.io.File;
import x10.util.Timer;
import caravan.util.MyLogger;
import caravan.util.Deque;
import x10.util.concurrent.AtomicLong;
import x10.util.concurrent.SimpleLatch;

class JobProducer {

  val m_tables: Tables;
  val m_engine: SearchEngineI;
  val m_taskQueue: Deque[Task];
  val m_freeBuffers: HashMap[Place, GlobalRef[JobBuffer]];
  val m_numBuffers: Long;
  var m_numRunning: AtomicLong = new AtomicLong(0);
  val m_latch: SimpleLatch = new SimpleLatch();
  val m_timer = new Timer();
  var m_lastSavedAt: Long;
  val m_saveInterval: Long;
  val m_refTimeForLogger: Long;
  var m_dumpFileIndex: Long;
  val m_logger: MyLogger;

  def this( _tables: Tables, _engine: SearchEngineI, _numBuffers: Long, _saveInterval: Long, _refTimeForLogger: Long ) {
    m_tables = _tables;
    m_engine = _engine;
    m_logger = new MyLogger( _refTimeForLogger );
    m_taskQueue = new Deque[Task]();
    if( m_tables.empty() ) {
      enqueueInitialTasks();
    } else {
      enqueueUnfinishedTasks();
    }
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
    val tasks = m_engine.createInitialTask( m_tables, Simulator.searchRegion() );
    m_taskQueue.pushLast( tasks.toRail() );
  }

  private def enqueueUnfinishedTasks() {
    val tasks = m_tables.createTasksForUnfinishedRuns();
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
    val toNotify:Boolean;
    atomic {
      var tasks: ArrayList[Task] = new ArrayList[Task]();
      val runningTasks = m_numRunning.addAndGet( -results.size() );
      for( res in results ) {
        val run = m_tables.runsTable.get( res.runId );
        run.storeResult( res.result, res.placeId, res.startAt - m_refTimeForLogger, res.finishAt - m_refTimeForLogger );
        val ps = run.parameterSet( m_tables );
        if( ps.isFinished( m_tables ) ) {
          val local_tasks = m_engine.onParameterSetFinished( m_tables, ps );
          for( task in local_tasks ) {
            tasks.add( task );
          }
        }
      }
      d("Producer saved " + results.size() + " results sent by " + caller);
      serializePeriodically();

      if( tasks.size() > 0 ) {
        m_taskQueue.pushLast( tasks.toRail() );
        if( m_freeBuffers.size() > 0 ) {
          val popped = popFreeBuffers( m_taskQueue.size() );
          for( ref in popped ) { refBuffers.add( ref ); }
        }
      }
      toNotify = (runningTasks == 0L) && m_taskQueue.empty();
    }

    if( refBuffers.size() > 0 ) {
      async {
        for( refBuf in refBuffers ) {
          at( refBuf ) @Uncounted async {
            refBuf().wakeUp();
          }
        }
        d("Producer has woken up " + refBuffers.size() + " free buffers");
      }
    }
    if(toNotify) notifyCompletion();
  }

  private atomic def serializePeriodically() {
    val now = m_timer.milliTime();
    if( now - m_lastSavedAt > m_saveInterval ) {
      val dump = "dump_" + m_dumpFileIndex;
      dumpTables( dump );
      m_lastSavedAt = now;
      m_dumpFileIndex += 1;
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
    m_numRunning.addAndGet( tasks.size );

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

  public def printJSON( psJson: String, runsJson: String ) {
    val f = new File(runsJson);
    val p = f.printer();
    p.println( m_tables.runsJson() );
    p.flush();
    val f2 = new File(psJson);
    val p2 = f2.printer();
    p2.println( m_tables.parameterSetsJson() );
    p2.flush();
  }

  public def dumpTables( filename: String ): void {
    val f = new File(filename);
    val p = f.printer();
    m_tables.writeBinary(p);
    p.flush();
  }

  public def waitCompletion() {
    d("waiting completion");
    m_latch.await();
  }
  public def notifyCompletion() {
    d("releasing latch");
    m_latch.release();
  }
}

