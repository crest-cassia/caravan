package caravan;

import x10.lang.System;
import x10.compiler.*;
import x10.util.ArrayList;
import x10.util.Timer;
import x10.compiler.Pragma;

class JobConsumer {

  val m_refBuffer: GlobalRef[JobBuffer];
  val m_timer = new Timer();
  var m_timeOut: Long = -1;
  val m_logger: Logger;
  val m_tasks: Deque[Task];
  val m_results: ArrayList[TaskResult];
  val m_sendInterval: Long;
  var m_lastResultSendTime: Long;
  var m_sendingResults: Boolean;

  def this( _refBuffer: GlobalRef[JobBuffer], refTimeForLogger: Long, sendInterval: Long ) {
    m_refBuffer = _refBuffer;
    m_logger = new Logger( refTimeForLogger );
    m_tasks = new Deque[Task]();
    m_results = new ArrayList[TaskResult]();
    m_sendInterval = sendInterval;
    saveResultsDone();
  }

  private def d(s:String) {
    if( here.id == 2 ) { m_logger.d(s); }
  }

  private def w(s:String) {
    m_logger.w(s);
  }

  def setExpiration( timeOutMilliTime: Long ) {
    m_timeOut = timeOutMilliTime;
  }

  private def saveResultsDone() {
    atomic {
      m_lastResultSendTime = m_timer.milliTime();
      m_sendingResults = false;
    }
  }

  def warnForLongProc( msg: String, proc: ()=>void ) {
    val from = m_timer.milliTime() - m_logger.m_refTime;
    proc();
    val to = m_timer.milliTime() - m_logger.m_refTime;
    if( (to - from) > 5000 ) {
      w("[Warning] proc takes more than 5 sec: " + from + " - " + to + " : " + msg);
    }
  }

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
      d("Consumer finished task " + task.taskId);

      if( readyToSendResults() || isExpired() ) {
        atomic { m_sendingResults = true; }
        val results = m_results.toRail();
        m_results.clear();
        warnForLongProc("saveResutls", () => {
          val refCons = new GlobalRef[JobConsumer]( this );
          at( refBuf ) async {
            refBuf().saveResults( results, refCons.home );
            at( refCons ) async {
              refCons().saveResultsDone();
            }
          }
          when( m_sendingResults == false ) { d("saveResults done"); };
        });
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

  private def runTask( task: Task ): TaskResult {
    val taskId = task.taskId;
    val startAt = m_timer.milliTime();
    val runPlace = here.id;
    val rcResults = task.run();
    val rc = rcResults.first;
    val results = rcResults.second;
    val finishAt = m_timer.milliTime();
    val tr = TaskResult( taskId, rc, results, runPlace, startAt, finishAt );
    return tr;
  }

  private def readyToSendResults(): Boolean {
    if( m_tasks.size() == 0 ) { return true; }
    val now = m_timer.milliTime();
    return ( now - m_lastResultSendTime > m_sendInterval );
  }

  def getTasksFromBufferOrRegisterFreePlace() {
    val refBuf = m_refBuffer;
    val timeOut = m_timeOut;
    val consPlace = here;
    val refCons = new GlobalRef[JobConsumer]( this );
    warnForLongProc("popTasks", () => {
      finish at( refBuf ) async {
        val tasks = refBuf().popTasksOrRegisterFreePlace( consPlace, timeOut );
        at( refCons ) async {
          refCons().m_tasks.pushLast( tasks );
        }
      }
    });
  }

  private def isExpired(): Boolean {
    return ((m_timeOut > 0) && (m_timer.milliTime() > m_timeOut));
  }
}

