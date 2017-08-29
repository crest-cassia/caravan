import caravan.Task;
import x10.io.File;

class TaskTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> TaskTest");
    testRun();
  }

  static public def testRun(): void {
    val taskId = 132;
    val argv = ["./dummy.sh","132","1","2","3","1234"];
    // val task = Task( taskId, argv );
    val task = Task( taskId as Long, argv as Rail[String] );

    p( task.toString() );
    assert task.taskId == taskId;

    val out = task.run();

    assert out.rc == 0;
    p( out.values );

    val f = new File( task.resultsFilePath() );
    assert f.exists();

    f.delete();
  }
}

