import x10.util.ArrayList;
import x10.io.File;
import caravan.Administrator;

class Main {

  static public def main( args: Rail[String] ) {
    if( args.size > 0 ) {
      val m = new Administrator();
      val timeOut = 3600 * 1000;
      val numProcPerBuf = 384;
      m.run( args, timeOut, numProcPerBuf );
    }
    else {
      Console.ERR.println("Usage:\n./a.out [command of searcher]");
      Console.ERR.println("Example:\n./a.out python ....");
    }
  }
}

