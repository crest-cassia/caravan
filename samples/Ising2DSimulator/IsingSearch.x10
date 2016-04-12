import caravan.Main;
import caravan.SearchEngines.GridSearcher;

class IsingSearch {

  static public def main( args: Rail[String] ) {
    val m = new Main();
    val engine = new GridSearcher();
    val seed = Long.parse( args(0) );
    m.run( engine, 3000000, 5000000, 4 );
  }
}
