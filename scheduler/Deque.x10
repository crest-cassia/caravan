package scheduler;

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

  public def popFirst( n:Long ): Rail[T] {
    val numPop = ( n < size() ) ? n : size();
    val ret = Unsafe.allocRailUninitialized[T]( numPop );
    if( n == 0 ) { return ret; }

    if( begin + numPop < capacity ) {
      Rail.copy( buffer, begin, ret, 0, numPop );
      begin = index( begin + numPop );
    }
    else {
      val s = capacity - begin;
      Rail.copy( buffer, begin, ret, 0, s );
      Rail.copy( buffer, 0, ret, s, numPop-s );
      begin = index( begin + numPop );
    }
    return ret;
  }

  public def popLast( n:Long ): Rail[T] {
    val numPop = ( n < size() ) ? n : size();
    val ret = Unsafe.allocRailUninitialized[T]( numPop );
    if( n == 0 ) { return ret; }

    if( end - numPop >= 0 ) {
      Rail.copy( buffer, end-numPop, ret, 0, numPop );
      end = end - numPop;
    }
    else {
      val newEnd = index( end-numPop );
      val s = capacity - newEnd;
      Rail.copy( buffer, newEnd, ret, 0, s );
      Rail.copy( buffer, 0, ret, s, numPop-s );
      end = newEnd;
    }
    return ret;
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
}
