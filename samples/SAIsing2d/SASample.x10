import caravan.Main;
import caravan.SearchEngines.FileInputSearcher;

class SASample {

  static public def main( args: Rail[String] ) {
    val m = new Main();
    Console.ERR.println("Initializing Searcher");
    if( args.size != 1 ) {
      Console.ERR.println("  Usage: ./a.out <model_input.txt>");
      throw new Exception("Invalid argument");
    }
    val engine = new FileInputSearcher( args(0), 1 );
    Console.ERR.println("starting Main::run");
    m.run( engine, 300000, 500000, 4 );
  }
}

