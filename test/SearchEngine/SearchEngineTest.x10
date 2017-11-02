import x10.util.ArrayList;
import caravan.SearchEngine;
import caravan.TaskResult;
import caravan.Task;

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

    val init_tasks = SearchEngine.createInitialTasks();
    p( init_tasks.size() );
    showTasks( init_tasks );

    val results = new Rail[TaskResult](2);
    results(0) = TaskResult(0, 0, [10.0, 20.0], 3, 100, 200 );
    results(1) = TaskResult(1, 0, [3.0, 4.0], 2, 100, 200 );
    for( r in results ) {
      val tasks = SearchEngine.sendResult( r.toLine(0) );
      showTasks( tasks );
    }
  }

  static private def showTasks(tasks: ArrayList[Task]): void {
    for( t in tasks ) {
      p( t.toString() );
    }
  }
}

