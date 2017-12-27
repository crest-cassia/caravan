package caravan;
import x10.io.Printer;
import x10.io.Marshal.LongMarshal;
import x10.io.Marshal.DoubleMarshal;

public struct TaskResult(
    taskId: Long,
    rc: Long,
    result: Rail[Double],
    placeId: Long,
    startAt: Long,
    finishAt: Long
  ) {

  public def toLine(refTime: Long): String {
    var s:String = String.format("%d %d %d %d %d", [taskId as Any, rc, placeId, startAt-refTime, finishAt-refTime] );
    for( r in result ) {
      s += " " + r.toString();
    }
    return s;
  }

  public def writeBinary(w: Printer, refTime: Long): void {
    val marshalLong = new LongMarshal();
    val marshalDouble = new DoubleMarshal();
    marshalLong.write( w, taskId );
    marshalLong.write( w, rc );
    marshalLong.write( w, placeId );
    marshalLong.write( w, startAt - refTime );
    marshalLong.write( w, finishAt - refTime );
    marshalLong.write( w, result.size );
    for( d in result ) {
      marshalDouble.write( w, d );
    }
  }
};

