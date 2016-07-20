package caravan;

import x10.util.ArrayList;
import x10.util.HashMap;
import x10.io.File;
import x10.util.Timer;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobProducer {

  val m_tables: Tables;
  val m_engine: SearchEngineI;
  val m_taskQueue: Deque[Task];
  val m_freeBuffers: HashMap[Place, GlobalRef[JobBuffer]];
  val m_numBuffers: Long;
  val m_timer = new Timer();
  var m_lastSavedAt: Long;
  val m_saveInterval: Long;
  var m_dumpFileIndex: Long;
  val m_logger: MyLogger;
  var m_isLockQueueAndFreeBuffers: Boolean = false; // lock for m_taskQueue and m_freeBuffers
  var m_isLockResults: Boolean = false;

  def this( _tables: Tables, _engine: SearchEngineI, _numBuffers: Long, _saveInterval: Long, refTimeForLogger: Long ) {
    m_tables = _tables;
    m_engine = _engine;
    m_logger = new MyLogger( refTimeForLogger );
    m_taskQueue = new Deque[Task]();
    if( m_tables.empty() ) {
      enqueueInitialTasks();
    } else {
      enqueueUnfinishedTasks();
    }
    m_freeBuffers = new HashMap[Place, GlobalRef[JobBuffer]]();
    m_numBuffers = _numBuffers;
    m_lastSavedAt = m_timer.milliTime();
    m_saveInterval = _saveInterval;
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

  public def saveResults( results: ArrayList[JobConsumer.RunResult] ) {
    when( !m_isLockResults ) { m_isLockResults = true; }
    var tasks: ArrayList[Task] = new ArrayList[Task]();

    d("Producer saving " + results.size() + " results");
    for( res in results ) {
      val run = m_tables.runsTable.get( res.runId );
      run.storeResult( res.result, res.placeId, res.startAt, res.finishAt );
      val ps = run.parameterSet( m_tables );
      if( ps.isFinished( m_tables ) ) {
        val local_tasks = m_engine.onParameterSetFinished( m_tables, ps );
        for( task in local_tasks ) {
          tasks.add( task );
        }
      }
    }
    d("Producer saved " + results.size() + " results");
    serializePeriodically();
    atomic { m_isLockResults = false; }

    when( !m_isLockQueueAndFreeBuffers ) { m_isLockQueueAndFreeBuffers = true; }
    m_taskQueue.pushLast( tasks.toRail() );
    val qSize = m_taskQueue.size();

    if( m_taskQueue.size() > 0 && m_freeBuffers.size() > 0 ) {   // only when there is a task and free buffer
      notifyFreeBuffer(qSize);
    }
    atomic { m_isLockQueueAndFreeBuffers = false; }
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

  private def notifyFreeBuffer(numBuffersToLaunch: Long) {
    // numBuffersToLaunch must be 0
    d("Producer notifying free buffers");

    val refBuffers = new ArrayList[GlobalRef[JobBuffer]]();
    for( entry in m_freeBuffers.entries() ) {
      val refBuf = entry.getValue();
      refBuffers.add( refBuf );
      if( refBuffers.size() >= numBuffersToLaunch ) { break; }
    }

    for( refBuf in refBuffers ) {
      m_freeBuffers.delete( refBuf.home );
      at( refBuf ) async {
        refBuf().wakeUp();
      }
    }
    d("Producer notified " + refBuffers.size() + " free buffers");
  }

  // return tasks if available.
  // if there is no task, register the buffer as free
  public def popTasksOrRegisterFreeBuffer( refBuf: GlobalRef[JobBuffer] ): Rail[Task] {
    when( !m_isLockQueueAndFreeBuffers ) { m_isLockQueueAndFreeBuffers = true; }
    d("Producer popTasks is called by " + refBuf.home );
    val n = calcNumTasksToPop();
    val tasks = m_taskQueue.popFirst( n );
    d("Producer sending " + tasks.size + " tasks to buffer" + refBuf.home);

    if( tasks.size == 0 ) {
      registerFreeBuffer( refBuf );
    }

    atomic { m_isLockQueueAndFreeBuffers = false; }
    return tasks;
  }

  private def calcNumTasksToPop(): Long {
    return Math.ceil((m_taskQueue.size() as Double) / (2.0*m_numBuffers)) as Long;
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
}

