package caravan;

import x10.compiler.*;
import x10.util.ArrayList;
import x10.util.Timer;
import x10.compiler.Pragma;
import caravan.SimulationOutput;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobConsumer {

  val m_refBuffer: GlobalRef[JobBuffer];
  val m_timer = new Timer();
  var m_timeOut: Long = -1;
  val m_logger: MyLogger;
  val m_tasks: Deque[Task];
  val m_results: ArrayList[RunResult];

  def this( _refBuffer: GlobalRef[JobBuffer], refTimeForLogger: Long ) {
    m_refBuffer = _refBuffer;
    m_logger = new MyLogger( refTimeForLogger );
    m_tasks = new Deque[Task]();
    m_results = new ArrayList[RunResult]();
  }

  private def d(s:String) {
    if( here.id == 1 ) { m_logger.d(s); }
  }

  def setExpiration( timeOutMilliTime: Long ) {
    m_timeOut = timeOutMilliTime;
  }

  static struct RunResult(
    runId: Long,
    result: SimulationOutput,
    placeId: Long,
    startAt: Long,
    finishAt: Long
  ) {};

  def run() {
    d("Consumer starting");
    val refBuf = m_refBuffer;

    getTasksFromBufferOrRegisterFreePlace();
    d("Consumer got initial tasks from buffer");

    while( m_tasks.size() > 0 ) {
      if( isExpired() ) { return; }

      val task = m_tasks.popFirst();
      val result = runTask( task );
      m_results.add( result );
      d("Consumer finished task " + task.runId);

      if( hasEnoughResults() ) {
        val results = m_results.toRail();
        m_results.clear();
        at( refBuf ) @Uncounted async {
          refBuf().saveResults( results );
        }
      }
      if( isExpired() ) { return; }

      if( m_tasks.size() == 0 ) {
        d("Consumer task queue is empty. getting tasks");
        getTasksFromBufferOrRegisterFreePlace();
        d("Consumer got " + m_tasks.size() + " tasks from buffer");
      }
    }

    d("Consumer finished");
  }

  private def runTask( task: Task ): RunResult {
    val runId = task.runId;
    val startAt = m_timer.milliTime();
    val runPlace = here.id;
    val localResult = task.run();
    val finishAt = m_timer.milliTime();
    val result = RunResult( runId, localResult, runPlace, startAt, finishAt );
    return result;
  }

  private def hasEnoughResults(): Boolean {
    val taskSize = m_tasks.size();
    if( taskSize == 0 ) { return true; }
    val minSize = 3;
    val numResults = m_results.size();
    return (numResults >= taskSize && numResults >= minSize );
  }

  def getTasksFromBufferOrRegisterFreePlace() {
    val refBuf = m_refBuffer;
    val timeOut = m_timeOut;
    val consPlace = here;
    val refCons = new GlobalRef[JobConsumer]( this );
    finish at( refBuf ) async {
      val tasks = refBuf().popTasksOrRegisterFreePlace( consPlace, timeOut );
      at( refCons ) async {
        refCons().m_tasks.pushLast( tasks );
      }
    }
  }

  private def isExpired(): Boolean {
    return ((m_timeOut > 0) && (m_timer.milliTime() > m_timeOut));
  }
}

