import x10.lang.System;
import caravan.Administrator;

class Main {

  static public def main( args: Rail[String] ) {
    if( args.size == 0 ) {
      Console.ERR.println("  Usage: ./a.out [command of searcher]");
      throw new Exception("Invalid argument");
    }

    val numProcPerBuf: Long = getLongOption("CARAVAN_NUM_PROC_PRE_BUF", 384);
    val timeOut: Long = getLongOption("CARAVAN_TIMEOUT", 86400) * 1000;

    val m = new Administrator();
    m.run( args, timeOut, numProcPerBuf );
  }

  static def getLongOption( envKey:String, defaultValue: Long ):Long {
    val n = System.getenv(envKey);
    if( n == null ) {
      return defaultValue;
    }
    else {
      return Long.parse(n);
    }
  }
}

