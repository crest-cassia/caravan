import caravan.Administrator;
import caravan.SearchEngines.GridSearcher;

class Main {

  static public def main( args: Rail[String] ) {
    val m = new Administrator();
    val engine = new GridSearcher( 0.2, 1 );
    if( args.size != 1 ) {
      Console.ERR.println("  Usage: ./a.out <seed>");
      throw new Exception("Invalid argument");
    }
    val seed = Long.parse( args(0) );
    m.run( engine, 3000000, 5000000, 4 );
  }
}
