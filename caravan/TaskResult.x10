package caravan;

public struct TaskResult(
    taskId: Long,
    rc: Long,
    result: Rail[Double],
    placeId: Long,
    startAt: Long,
    finishAt: Long
  ) {

  public def toLine( refTime: Long): String {
    var s:String = String.format("%d %d %d %d %d", [taskId as Any, rc, placeId, startAt-refTime, finishAt-refTime] );
    for( r in result ) {
      s += " " + r.toString();
    }
    return s;
  }
};

