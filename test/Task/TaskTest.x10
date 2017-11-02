import caravan.Task;
import x10.io.File;

class TaskTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> TaskTest");
    testRun();
    testRunWithoutResultFile();
  }

  static public def testRun(): void {
    val taskId = 132;
    val cmd = "echo 132 1 2 3 1234 > _results.txt";
    val task = Task( taskId, cmd );

    p( task.toString() );
    assert task.taskId == taskId;

    val out = task.run();

    assert out.first == 0;
    p( out.second.toString() );

    val dir = new File( task.workDirPath() );
    assert dir.isDirectory();
    
    val f = new File( task.resultsFilePath() );
    assert f.exists();
  }

  static public def testRunWithoutResultFile(): void {
    val taskId = 1043;
    val cmd = "echo foo 1 2 3 1234";
    val task = Task( taskId, cmd );

    assert task.taskId == taskId;
    val out = task.run();

    assert out.first == 0;
    assert out.second.size == 0; // empty Rail

    val dir = new File( task.workDirPath() );
    assert dir.isDirectory();
  }

}

