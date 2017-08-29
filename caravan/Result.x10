package caravan;

public struct Result( taskId: Long, rc: Long, values: Rail[Double] ) {

  public def toString(): String {
    return "{ taskId: " + taskId + ", rc: " + rc + ", values: " + values.toString();
  }
}

