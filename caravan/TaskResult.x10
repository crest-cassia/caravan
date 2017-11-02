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
    val s = String.format("%l %l %l %l %l", [taskId as Any, rc, placeId, startAt-refTime, finishAt-refTime] );
    var line: String = s;
    for( r in result ) {
      line += " " + r.toString();
    }
    return line;
  }
};

