package test;

import caravan.Deque;

class DequeTest {

  static public def p( obj:Any ): void {
    Console.ERR.println( obj );
  }

  static private def cmp(q: Rail[Long], r: Rail[Long]): Boolean {
    if( q.size != r.size ) { return false; }
    if( q.size == 0 ) { return true; }
    for(i in 0..(q.size-1) ) {
      if( q(i) != r(i) ) { return false; }
    }
    return true;
  }

  static private def cmp(q: Deque[Long], r: Rail[Long]): Boolean {
    return cmp(q.toRail(), r);
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
    assert q.size() == 0;
    q.pushLast(1);
    q.pushLast(2);
    q.pushLast(3);
    p( q );
    assert cmp(q,[1,2,3]) : q;
    q.pushLast(4);
    assert cmp(q,[1,2,3,4]) : q;
  }

  static public def testGrow2(): void {
    val q = new Deque[Long](4);
    p( q );
    assert q.size() == 0;
    assert q.capacity() == 4;

    q.pushFirst(4);
    q.pushFirst(3);
    q.pushLast(5);
    p( q );
    assert cmp(q, [3,4,5]) : q;
    assert q.capacity() == 4 : q.capacity();

    assert q.first() == 3;
    assert q.last() == 5;

    q.pushLast(6);
    assert cmp(q, [3,4,5,6]) : q;
    assert q.capacity() > 4 : q.capacity();

    p("popFirst:");
    assert q.popFirst() == 3;
    assert q.popFirst() == 4;
    assert q.popFirst() == 5;
    assert cmp(q, [6 as Long]) : q;
    q.pushFirst(7); q.pushFirst(8); q.pushFirst(9);
    p( q );
    assert cmp(q, [9,8,7,6]) : q;
  }

  static public def testPushFirstMultiple(): void {
    val q = new Deque[Long](4);
    q.pushFirst( [1,2,3] );
    p( q );
    val r = q.toRail();
    assert cmp(q, [1,2,3]): q;
    q.pushFirst( [4,5,6] );
    p( q );
    assert cmp(q, [4,5,6,1,2,3]): q;

    val q2 = new Deque[Long](4);
    q2.pushFirst( [1,2,3,4,5,6,7,8,9,10] );
    p( q2 );
    assert cmp(q2, [1,2,3,4,5,6,7,8,9,10]): q;
  }

  static public def testPushLastMultiple(): void {
    val q = new Deque[Long](4);
    q.pushLast( [1,2,3] );
    assert cmp(q, [1,2,3]): q;
    q.pushLast( [4,5,6] );
    assert cmp(q, [1,2,3,4,5,6]): q;

    val q2 = new Deque[Long](4);
    q2.pushLast( [1,2,3,4,5,6,7,8,9,10] );
    p( q2 );
    assert cmp(q2, [1,2,3,4,5,6,7,8,9,10]): q;

    val q3 = new Deque[Long](4);
    q3.pushFirst( [1,2,3] );
    q3.popLast(); q3.popLast();
    q3.pushLast( [2,3] );
    p( q3 );
    assert cmp(q3, [1,2,3]): q;
  }

  static public def testPopFirstMultiple(): void {
    val q = new Deque[Long](4);
    q.pushLast( [1,2,3] );
    val ret = q.popFirst( 2 );
    assert cmp(ret,[1,2]) : ret;
    assert cmp(q,[3 as Long]) : q;

    q.pushFirst( ret );
    assert cmp(q,[1,2,3]) : q;
    val ret2 = q.popFirst( 5 );
    assert cmp(ret2,[1,2,3]) : ret2;
    assert q.size() == 0 : q;

    val q2 = new Deque[Long](4);
    q2.pushFirst( [1,2] ); q2.pushLast(3);
    val ret3 = q2.popFirst( 3 );
    assert cmp(ret3,[1,2,3]) : ret3;
    assert q2.size() == 0 : q2;
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

