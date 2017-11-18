package scheduler;
import x10.util.Timer;

public class MyLogger {

  val m_timer: Timer = new Timer();
  public val m_refTime: Long;

  public def this( refTime: Long ) {
    m_refTime = refTime;
  }

  private def t():Long {
    return (m_timer.milliTime() - m_refTime);
  }

  public def d(message: String) {
    Console.ERR.println( t().toString() + " [" + here + "] : " + message );
  }
}

