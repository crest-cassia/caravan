import caravan.Main;
import caravan.SearchEngines.GridSearcher;

class IsingSearch {

  static public def main( args: Rail[String] ) {
    val m = new Main();
    val engine = new GridSearcher( 0.2, 1 );
    val seed = Long.parse( args(0) );
    m.run( engine, 3000000, 5000000, 4 );
  }
}
