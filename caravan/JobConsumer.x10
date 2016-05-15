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
  val m_logger = new MyLogger();

  def this( _refBuffer: GlobalRef[JobBuffer] ) {
    m_refBuffer = _refBuffer;
  }

  private def d(s:String) {
    if( here.id == 1 ) { m_logger.d(s); }
  }

  def setExpiration( timeOutMilliTime: Long ) {
    m_timeOut = m_timer.milliTime() + timeOutMilliTime;
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

    val tasks = getTasksFromBuffer();
    while( tasks.size() > 0 ) {
      val task = tasks.popFirst();
      val result = runTask( task );

      at( refBuf ) {
        refBuf().saveResult( result );
      }
      if( isExpired() ) { return; }

      if( tasks.size() == 0 ) {
        d("Consumer task queue is empty. getting tasks");
        val newTasks = getTasksFromBuffer();
        tasks.pushLast( newTasks.toRail() );
        d("Consumer got tasks from buffer");
      }
    }

    d("Consumer registering self as a free place");
    val place = here;
    at( refBuf ) {
      refBuf().registerFreePlace( place );
    }
    d("Consumer registered self as a free place");
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

  def getTasksFromBuffer(): Deque[Task] {
    val refBuf = m_refBuffer;
    val tasks = at( refBuf ) {
      return refBuf().popTasks();
    };
    val q = new Deque[Task]();
    q.pushLast( tasks );
    return q;
  }

  private def isExpired(): Boolean {
    return ((m_timeOut > 0) && (m_timer.milliTime() > m_timeOut));
  }
}

