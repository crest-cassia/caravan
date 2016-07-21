package caravan;

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

  def this( _refBuffer: GlobalRef[JobBuffer], refTimeForLogger: Long ) {
    m_refBuffer = _refBuffer;
    m_logger = new MyLogger( refTimeForLogger );
    m_tasks = new Deque[Task]();
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
      d("Consumer finished task " + task.runId);

      at( refBuf ) async {
        refBuf().saveResult( result );
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

  def getTasksFromBufferOrRegisterFreePlace() {
    val refBuf = m_refBuffer;
    val timeOut = m_timeOut;
    val consPlace = here;
    val refCons = new GlobalRef[JobConsumer]( this );

    @Pragma(Pragma.FINISH_HERE) finish at( refBuf ) async {
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

