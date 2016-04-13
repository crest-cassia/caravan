import caravan.Main;
import caravan.SearchEngines.GridSearcher;

class WSNSearch {

  static public def main( args: Rail[String] ) {
    val m = new Main();
    val engine = new GridSearcher();
    val seed = Long.parse( args(0) );
    m.run( engine, 300000, 500000, 4 );
  }
}
