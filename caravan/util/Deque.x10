package caravan.util;

import x10.util.GrowableRail;

public class Deque[T] {

  private var buffer: Rail[T];
  private var capacity: Long;
  private var begin: Long;
  private var end: Long;

  public def this() {
    this(8);
  }

  public def this( cap: Long ) {
    assert ( cap > 0 );
    buffer = Unsafe.allocRailZeroed[T]( cap );
    capacity = cap;
    begin = 0;
    end = 0;
  }

  public def empty(): Boolean {
    return ( begin == end );
  }

  public def size(): Long {
    if( end < begin ) {
      return end + capacity - begin;
    }
    else {
      return end - begin;
    }
  }

  public def first(): T {
    assert ( !empty() );
    return buffer(begin);
  }

  public def last(): T {
    assert ( !empty() );
    return buffer( index(end-1) );
  }

  public def pushFirst( item:T ): void {
    if( size() == capacity-1 ) {
      val newCap = capacity * 2;
      grow(newCap);
    }

    val idx = index( begin-1 );
    buffer(idx) = item;
    begin = idx;
  }

  public def pushLast( item:T ): void {
    if( size() == capacity-1 ) {
      val newCap = capacity * 2;
      grow(newCap);
    }

    buffer(end) = item;
    end = index( end+1 );
  }

  public def popFirst(): T {
    val f = buffer( begin );
    begin = index( begin + 1 );
    return f;
  }

  public def popLast(): T {
    end = index( end-1 );
    return buffer(end);
  }

  public def pushFirst( items: Rail[T] ): void {
    val newSize = size() + items.size;
    growBufferIfNecessary( newSize );

    if( begin - items.size >= 0 ) {
      val newBegin = begin - items.size;
      Rail.copy( items, 0, buffer, newBegin, items.size );
      begin = newBegin;
    }
    else {
      val newBegin = index( begin - items.size );
      Rail.copy( items, items.size-begin, buffer, 0, begin );
      Rail.copy( items, 0, buffer, newBegin, items.size-begin );
      begin = newBegin;
    }
  }

  public def pushLast( items: Rail[T] ): void {
    val newSize = size() + items.size;
    growBufferIfNecessary( newSize );

    if( end + items.size < capacity ) {
      Rail.copy( items, 0, buffer, end, items.size );
      end = index( end + items.size );
    }
    else {
      val s = capacity - end;
      Rail.copy( items, 0, buffer, end, s );
      Rail.copy( items, s, buffer, 0, items.size - s );
      end = index( end + items.size );
    }
  }

  public def toRail(): Rail[T] {
    val size = size();
    val ans = Unsafe.allocRailUninitialized[T](size);

    if( begin <= end ) {
      Rail.copy( buffer, begin, ans, 0, size );
    }
    else {
      val sizeA = capacity - begin;
      Rail.copy( buffer, begin, ans, 0, sizeA );
      Rail.copy( buffer, 0, ans, sizeA, end );
    }
    return ans;
  }

  private def index( n:Long ): Long {
    return (n + capacity) % capacity;
  }

  private def growBufferIfNecessary( newSize: Long ): void {
    if( capacity <= newSize ) {
      var newCapacity:Long = capacity * 2;
      while( newCapacity <= newSize ) {
        newCapacity *= 2;
      }
      grow( newCapacity );
    }
  }

  private def grow( newCapacity: Long ):void {
    assert ( newCapacity >= capacity );

    val tmp = Unsafe.allocRailUninitialized[T]( newCapacity );
    if( begin <= end ) {
      Rail.copy( buffer, 0, tmp, 0, capacity );
      Unsafe.clearRail( tmp, capacity, newCapacity-capacity );
      Unsafe.dealloc( buffer );
      buffer = tmp;
      capacity = newCapacity;
    }
    else {
      val numEmpty: Long = newCapacity - size();
      Rail.copy( buffer, 0, tmp, 0, end );
      Unsafe.clearRail( tmp, end, numEmpty );
      val newBegin = end + numEmpty;
      Rail.copy( buffer, begin, tmp, end+numEmpty, newCapacity-newBegin );
      Unsafe.dealloc( buffer );
      buffer = tmp;
      capacity = newCapacity;
      begin = newBegin;
    }
  }

  public def toString(): String {
    return "queue: " + toRail() +
      "\n  buffer: " + buffer.toString() +
      "\n  capacity: " + capacity +
      "\n  begin: " + begin +
      "\n  end: " + end;
  }

  static public def p( obj:Any ) {
    Console.OUT.println( obj );
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

  static public def main( args: Rail[String] ) {
    p("testGrow1 ---");
    testGrow1();
    p("testGrow2 ---");
    testGrow2();
    p("testPushFirst multiple ---");
    testPushFirstMultiple();
    p("testPushLast multiple ---");
    testPushLastMultiple();
  }
}
