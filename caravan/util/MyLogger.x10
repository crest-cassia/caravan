package caravan.util;
import x10.util.Timer;

public class MyLogger {

  val m_timer: Timer = new Timer();
  val m_startAt: Long;

  public def this() {
    m_startAt = m_timer.milliTime();
  }

  private def t():Long {
    return (m_timer.milliTime() - m_startAt);
  }

  public def d(message: String) {
    Console.ERR.println( t().toString() + " [" + here + "] : " + message );
  }
}

