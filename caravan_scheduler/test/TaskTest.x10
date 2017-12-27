package test;

import caravan.Task;
import x10.io.File;

class TaskTest {

  static public def p( obj:Any ): void {
    Console.ERR.println( obj );
  }

  static private def cmp(q: Rail[Double], r: Rail[Double]): Boolean {
    if( q.size != r.size ) { return false; }
    if( q.size == 0 ) { return true; }
    for(i in 0..(q.size-1) ) {
      if( q(i) != r(i) ) { return false; }
    }
    return true;
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
    assert cmp(out.second, [132.0, 1.0, 2.0, 3.0, 1234.0]) : out.second;

    val dir = new File( task.workDirPath() );
    assert dir.isDirectory();
    
    val f = new File( task.resultsFilePath() );
    assert f.exists();
  }

  static public def testRunWithoutResultFile(): void {
    val taskId = 1043;
    val cmd = "pwd > pwd.txt";
    val task = Task( taskId, cmd );

    assert task.taskId == taskId;
    val out = task.run();

    assert out.first == 0;
    assert out.second.size == 0; // empty Rail

    val dir = new File( task.workDirPath() );
    assert dir.isDirectory();
    val f = new File( task.workDirPath()+"/pwd.txt" );
    assert f.exists();
  }
}

