package caravan;

import x10.util.ArrayList;
import x10.io.File;
import x10.util.Timer;
import x10.util.concurrent.AtomicBoolean;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobProducer {

  val m_tables: Tables;
  val m_engine: SearchEngineI;
  val m_taskQueue: Deque[Task];
  val m_freeBuffers: ArrayList[GlobalRef[JobBuffer]];
  val m_numBuffers: Long;
  val m_timer = new Timer();
  var m_lastSavedAt: Long;
  val m_saveInterval: Long;
  var m_dumpFileIndex: Long;
  val m_logger: MyLogger = new MyLogger();
  val m_isLockQueue: AtomicBoolean = new AtomicBoolean(false);
  val m_isLockResults: AtomicBoolean = new AtomicBoolean(false);
  val m_isLockBuffers: AtomicBoolean = new AtomicBoolean(false);

  def this( _tables: Tables, _engine: SearchEngineI, _numBuffers: Long, _saveInterval: Long ) {
    m_tables = _tables;
    m_engine = _engine;
    m_taskQueue = new Deque[Task]();
    if( m_tables.empty() ) {
      enqueueInitialTasks();
    } else {
      enqueueUnfinishedTasks();
    }
    m_freeBuffers = new ArrayList[GlobalRef[JobBuffer]]();
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

  public def registerFreeBuffer( refBuffer: GlobalRef[JobBuffer] ) {
    when( !m_isLockBuffers.get() ) { m_isLockBuffers.set(true); }
    d("Producer registering free buffer");
    m_freeBuffers.add( refBuffer );
    d("Producer registered free buffer");
    m_isLockBuffers.set(false);
  }

  public def saveResults( results: ArrayList[JobConsumer.RunResult] ) {
    when( !m_isLockResults.get() ) { m_isLockResults.set(true); }
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
    m_isLockResults.set(false);

    when( !m_isLockQueue.get() ) { m_isLockQueue.set(true); }
    m_taskQueue.pushLast( tasks.toRail() );
    val qSize = m_taskQueue.size();
    m_isLockQueue.set(false);

    d("Producer saved " + results.size() + " results");
    serializePeriodically();

    when( !m_isLockBuffers.get() ) { m_isLockBuffers.set(true); }
    notifyFreeBuffer(qSize);
    m_isLockBuffers.set(false);
  }

  private atomic def serializePeriodically() {
    val now = m_timer.milliTime();
    if( now - m_lastSavedAt > m_saveInterval ) {
      val psjson = "parameter_sets_" + m_dumpFileIndex + ".json";
      val runjson = "runs_" + m_dumpFileIndex + ".json";
      printJSON(psjson, runjson);
      m_lastSavedAt = now;
      m_dumpFileIndex += 1;
    }
  }

  private def notifyFreeBuffer(numBuffersToLaunch: Long) {
    d("Producer notifying free buffers");

    val refBuffers = new ArrayList[GlobalRef[JobBuffer]]();
    while( m_freeBuffers.size () > 0 && refBuffers.size() < numBuffersToLaunch ) {
      val freeBuf = m_freeBuffers.removeFirst();
      refBuffers.add( freeBuf );
    }
    for( refBuf in refBuffers ) {
      at( refBuf ) {
        refBuf().wakeUp();
      }
    }
    d("Producer notified free buffers");
  }

  public def popTasks(): Rail[Task] {
    when( !m_isLockQueue.get() ) { m_isLockQueue.set(true); }
    d("Producer popTasks is called");
    val n = calcNumTasksToPop();
    val tasks = m_taskQueue.popFirst( n );
    d("Producer sending " + tasks.size + " tasks to buffer");
    m_isLockQueue.set(false);
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

