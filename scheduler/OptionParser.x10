package scheduler;

import x10.lang.System;

public class OptionParser {

  static public val availableOptions = [
    ["CARAVAN_NUM_PROC_PER_BUF", "# of consumer processes for each buffer proc", 384],
    ["CARAVAN_TIMEOUT", "timeout duration in sec", 86400],
    ["CARAVAN_SEND_RESULT_INTERVAL", "interval to send results in sec", 3],
    ["CARAVAN_LOG_LEVEL", "log level", 1]
  ];

  static public def printHelp() {
    Console.ERR.println("Available Options:");
    for( opt in availableOptions ) {
      Console.ERR.println("  " + opt(0) + "\t: " + opt(1) + " (default:" + opt(2) + ")");
    }
  }

  static public def printDetectedOptions() {
    for( opt in availableOptions ) {
      val key = opt(0) as String;
      val n = System.getenv(key);
      if( n != null ) {
        Console.ERR.println("Option " + key + " is detected : " + n);
        val parsed = Long.parse(n);
      }
    }
  }

  static public def get( key: String ): Long {
    for( x in availableOptions ) {
      val k = x(0) as String;
      if( key.equals(k) ) {
        return getLongOption( key, x(2) as Long );
      }
    }
    Console.ERR.println("[Error] Unknown option : " + key);
    throw new Exception("invalid option");
  }

  static def getLongOption( envKey: String, defaultValue: Long ): Long {
    val n = System.getenv(envKey);
    if( n == null ) {
      return defaultValue;
    }
    else {
      return Long.parse(n);
    }
  }
}

