import caravan.Administrator;

class Main {

  static public def main( args: Rail[String] ) {
    if( args.size == 0 ) {
      Console.ERR.println("  Usage: ./a.out [command of searcher]");
      throw new Exception("Invalid argument");
    }
    val numProcPerBuf = 4;
    val timeOut = 3600;
    val m = new Administrator();
    m.run( args, timeOut, numProcPerBuf );
  }
}

