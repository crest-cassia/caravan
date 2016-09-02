import caravan.Administrator;
import caravan.SearchEngines.GridSearcher;

class WSNSearch {

  static public def main( args: Rail[String] ) {
    val m = new Administrator();
    val engine = new GridSearcher( 5, 1 );
    if( args.size != 1 ) {
      Console.ERR.println("  Usage: ./a.out <seed>");
      throw new Exception("Invalid argument");
    }
    val seed = Long.parse( args(0) );
    m.run( engine, 300000, 500000, 4 );
  }
}
