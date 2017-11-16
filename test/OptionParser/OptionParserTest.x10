import caravan.OptionParser;

class OptionParserTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> TaskTest");
    testRun();
  }

  static public def testRun(): void {
    OptionParser.printHelp();

    OptionParser.printDetectedOptions();

    p( OptionParser.get("CARAVAN_NUM_PROC_PER_BUF") );
    p( OptionParser.get("CARAVAN_TIMEOUT") );
    p( OptionParser.get("CARAVAN_SEND_RESULT_INTERVAL") );
    p( OptionParser.get("CARAVAN_LOG_LEVEL") );
  }
}

