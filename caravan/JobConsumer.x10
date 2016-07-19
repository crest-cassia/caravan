package caravan;

import x10.util.ArrayList;
import x10.util.Timer;
import caravan.SimulationOutput;
import caravan.util.MyLogger;
import caravan.util.Deque;

class JobConsumer {

  val m_refBuffer: GlobalRef[JobBuffer];
  val m_timer = new Timer();
  var m_timeOut: Long = -1;
  val m_logger: MyLogger;

  def this( _refBuffer: GlobalRef[JobBuffer], refTimeForLogger: Long ) {
    m_refBuffer = _refBuffer;
    m_logger = new MyLogger( refTimeForLogger );
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

    val tasks = getTasksFromBufferOrRegisterFreePlace();
    d("Consumer got initial tasks from buffer");

    while( tasks.size() > 0 ) {
      if( isExpired() ) { return; }

      val task = tasks.popFirst();
      val result = runTask( task );
      d("Consumer finished task " + task.runId);

      at( refBuf ) {
        refBuf().saveResult( result );
      }
      if( isExpired() ) { return; }

      if( tasks.size() == 0 ) {
        d("Consumer task queue is empty. getting tasks");
        val newTasks = getTasksFromBufferOrRegisterFreePlace();
        tasks.pushLast( newTasks.toRail() );
        d("Consumer got tasks from buffer");
        d("  Tasks : " + newTasks.toRail() );
      }
    }

    d("Consumer finished");
  }

  private def runTask( task: Task ): RunResult {
    val runId = task.runId;
    // m_logger.fine("Consumer#runTask " + runId + " at " + here);
    val startAt = m_timer.milliTime();
    val runPlace = here.id;
    val localResult = task.run();
    val finishAt = m_timer.milliTime();
    val result = RunResult( runId, localResult, runPlace, startAt, finishAt );
    return result;
  }

  def getTasksFromBufferOrRegisterFreePlace(): Deque[Task] {
    val refBuf = m_refBuffer;
    val timeOut = m_timeOut;
    val consPlace = here;
    val tasks = at( refBuf ) {
      return refBuf().popTasksOrRegisterFreePlace( consPlace, timeOut );
    };
    val q = new Deque[Task]();
    q.pushLast( tasks );
    return q;
  }

  private def isExpired(): Boolean {
    return ((m_timeOut > 0) && (m_timer.milliTime() > m_timeOut));
  }
}

