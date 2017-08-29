import caravan.SearchEngine;
import caravan.Result;

class SearchEngineTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> SearchEngineTest");
    testLaunch();
  }

  static public def testLaunch(): void {

    val argv = ["python", "-u", "dummy_engine.py"];
    SearchEngine.launchSearcher(argv);

    assert SearchEngine.pidFilePointers(0) != 0;
    assert SearchEngine.pidFilePointers(1) != 0;
    assert SearchEngine.pidFilePointers(2) != 0;

    val tasks = SearchEngine.createInitialTasks();
    p( tasks.size() );
    for( t in tasks ) {
      p( t.toString() );
    }

    val results = new Rail[Result](2);
    results(0) = Result(0, 0, [10.0, 20.0]);
    results(1) = Result(1, 0, [3.0, 4.0]);
    val tasks2 = SearchEngine.onTasksFinished( results );
    for( t in tasks2 ) {
      p( t.toString() );
    }
  }
}

