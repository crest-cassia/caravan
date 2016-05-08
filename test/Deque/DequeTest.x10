import caravan.util.Deque;

class DequeTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> DequeTest");

    p(">>> #testGrow1");
    testGrow1();

    p(">>> #testGrow2");
    testGrow2();

    p(">>> testPushFirstMultiple");
    testPushFirstMultiple();

    p(">>> testPushLastMultiple");
    testPushLastMultiple();

    p(">>> testPopFirstMultiple");
    testPopFirstMultiple();

    p(">>> testPopLastMultiple");
    testPopLastMultiple();
  }

  static public def testGrow1(): void {
    val q = new Deque[Long](4); // set capacity to 4 for testing
    p( q );
    p( q.size() );
    q.pushLast(1);
    q.pushLast(2);
    q.pushLast(3);
    p( q );
    q.pushLast(4);
    p( q );
  }

  static public def testGrow2(): void {
    val q = new Deque[Long](4);
    p( q );

    q.pushFirst(4);
    q.pushFirst(3);
    q.pushLast(5);
    p( q );

    p( "first: " + q.first() );
    p( "last: " + q.last() );

    q.pushLast(6);
    p( q );
    p("size:" + q.size() );

    p("popFirst:");
    p( q.popFirst() );
    p( q.popFirst() );
    p( q.popFirst() );
    p( q );
    q.pushFirst(7); q.pushFirst(8); q.pushFirst(9);
    p( q );
  }

  static public def testPushFirstMultiple(): void {
    val q = new Deque[Long](4);
    q.pushFirst( [1,2,3] );
    p( q );
    q.pushFirst( [4,5,6] );
    p( q );

    val q2 = new Deque[Long](4);
    q2.pushFirst( [1,2,3,4,5,6,7,8,9,10] );
    p( q2 );
  }

  static public def testPushLastMultiple(): void {
    val q = new Deque[Long](4);
    q.pushLast( [1,2,3] );
    p( q );
    q.pushLast( [4,5,6] );
    p( q );

    val q2 = new Deque[Long](4);
    q2.pushLast( [1,2,3,4,5,6,7,8,9,10] );
    p( q2 );

    val q3 = new Deque[Long](4);
    q3.pushFirst( [1,2,3] );
    q3.popLast(); q3.popLast();
    q3.pushLast( [2,3] );
    p( q3 );
  }

  static public def testPopFirstMultiple(): void {
    val q = new Deque[Long](4);
    q.pushLast( [1,2,3] );
    val ret = q.popFirst( 2 );
    p( ret );
    p( q );

    q.pushFirst( ret );
    val ret2 = q.popFirst( 5 );
    p( ret2 );
    p( q );

    val q2 = new Deque[Long](4);
    q2.pushFirst( [1,2] ); q2.pushLast(3);
    val ret3 = q2.popFirst( 3 );
    p( ret3 );
    p( q2 );
  }

  static public def testPopLastMultiple(): void {
    val q = new Deque[Long](4);
    q.pushLast( [1,2,3] );
    val ret = q.popLast( 2 );
    p( ret );
    p( q );

    q.pushLast( ret );
    val ret2 = q.popLast( 5 );
    p( ret2 );
    p( q );

    val q2 = new Deque[Long](4);
    q2.pushFirst( [1,2] ); q2.pushLast(3);
    val ret3 = q2.popLast( 3 );
    p( ret3 );
    p( q2 );
  }
}

