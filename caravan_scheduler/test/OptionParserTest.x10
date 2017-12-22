package test;

import caravan.OptionParser;
import x10.lang.System;

class OptionParserTest {

  static public def p( obj:Any ): void {
    Console.ERR.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> OptionParserTest");
    testDefaults();
  }

  static public def testDefaults(): void {
    val opts = OptionParser.availableOptions;
    assert OptionParser.get("CARAVAN_NUM_PROC_PER_BUF") == opts(0)(2);
    assert OptionParser.get("CARAVAN_TIMEOUT") == opts(1)(2);
    assert OptionParser.get("CARAVAN_SEND_RESULT_INTERVAL") == opts(2)(2);
    assert OptionParser.get("CARAVAN_LOG_LEVEL") == opts(3)(2);

    val detected = OptionParser.detectedOptions();
    assert detected.size() == 0 : detected;
  }
}

