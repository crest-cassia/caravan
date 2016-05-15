package caravan;

import x10.util.ArrayList;
import x10.io.Printer;
import x10.io.Marshal.LongMarshal;
import x10.io.Marshal.DoubleMarshal;
import caravan.util.JSON;
import caravan.ParameterSet;

public class Run {
  public val id: Long;
  public var placeId: Long;
  public var startAt: Long = -1;
  public var finishAt: Long = -1;
  val params: Simulator.InputParameters;
  val seed: Long;
  public var result: SimulationOutput;
  public var finished: Boolean;
  val parentPSId: Long;

  def this( _id:Long, _ps: ParameterSet, _seed: Long ) {
    id = _id;
    parentPSId = _ps.id;
    seed = _seed;
    params = Simulator.deregularize( _ps.point );
    finished = false;
  }

  public static def loadJSON( json: JSON.Value, table: Tables ) {
    val id = json("id").toLong();
    val parentPSId = json("parentPSId").toLong();
    val ps = table.psTable.get(parentPSId);
    val seed = json("seed").toLong();

    val run = new Run( id, ps, seed );

    if( json("startAt").toLong() != -1 ) {
      val res = SimulationOutput.loadJSON( json("result") );
      val placeId = json("placeId").toLong();
      val startAt = json("startAt").toLong();
      val finishAt = json("finishAt").toLong();
      run.storeResult( res, placeId, startAt, finishAt );
    }

    return run;
  }

  public def generateTask(): Task {
    val task = new Task( id, params, seed );
    return task;
  }

  def unfinished(): Boolean {
    return (startAt == -1);
  }

  def parameterSet( table: Tables ): ParameterSet {
    return table.psTable.get( parentPSId );
  }

  def storeResult( _result: SimulationOutput, _placeId: Long, _startAt: Long, _finishAt: Long ) {
    result = _result;
    placeId = _placeId;
    startAt = _startAt;
    finishAt = _finishAt;
    finished = true;
  }

  def toString(): String {
    val str = "{ id: " + id + ", parentPSId: " + parentPSId + ", seed: " + seed +
              ", result: " + result +
              ", placeId: " + placeId + ", startAt: " + startAt + ", finishAt: " + finishAt + " }";
    return str;
  }

  def toJson(): String {
    val str = "{ \"id\": " + id + ", \"parentPSId\": " + parentPSId + ", \"seed\": " + seed +
              ", \"result\": " + result +
              ", \"placeId\": " + placeId + ", \"startAt\": " + startAt + ", \"finishAt\": " + finishAt + " }";
    return str;
  }

  public def writeBinary( w: Printer ): void {
    val marshal_long = new LongMarshal();
    val marshal_double = new DoubleMarshal();
    marshal_long.write( w, id );
    marshal_long.write( w, parentPSId );
    marshal_long.write( w, seed );

    for( x in result.values ) {
      marshal_double.write( w, x );
    }

    marshal_long.write( w, placeId );
    marshal_long.write( w, startAt );
    marshal_long.write( w, finishAt );
  }
}
