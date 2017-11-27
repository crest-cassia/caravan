package scheduler;
import x10.util.Timer;

public class MyLogger {

  val m_timer: Timer = new Timer();
  public val m_refTime: Long;
  public var m_logLevel: Long;

  public def this( refTime: Long ) {
    m_refTime = refTime;
    m_logLevel = OptionParser.get("CARAVAN_LOG_LEVEL");
  }

  private def t():Long {
    return (m_timer.milliTime() - m_refTime);
  }

  public def d(message: String) {
    if( m_logLevel > 0 ) {
      Console.ERR.println( t().toString() + " [" + here + "] : " + message );
    }
  }
}

