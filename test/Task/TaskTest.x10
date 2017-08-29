import caravan.Task;

class Task {

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
  }

}

