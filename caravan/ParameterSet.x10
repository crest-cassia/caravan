package caravan;

import x10.util.ArrayList;
import x10.util.Pair;
import caravan.util.JSON;

public class ParameterSet( id: Long, point: Point{self.rank==Simulator.numParams} ) {
  public val runIds: ArrayList[Long] = new ArrayList[Long]();

  public def toString(): String {
    val str = "{ id: " + id + ", point: " + point + ", params: " + Simulator.deregularize(point) + " }";
    return str;
  }

  static public def loadJSON( json: JSON.Value ): ParameterSet {
    val id = json("id").toLong();
    val coordinates = new Rail[Long](Simulator.numParams);
    for( i in 0..(Simulator.numParams-1) ) {
      coordinates(i) = json("point")(i).toLong();
    }
    val point = Point.make( coordinates );
    return new ParameterSet( id, point );
  }

  public def toJson(): String {
    val str = "{ " +
                "\"id\": " + id +
                ", \"point\": " + point.toString() +
                ", \"params\": " + Simulator.deregularize(point).toJson() +
              " }";
    return str;
  }

  public def writeBinary( w: Writer ): void {
    val marshal_long = new LongMarshal();
    marshal_long.write( w, id );
    for( i in 0..(point.rank-1) ) {
      marshal_long.write( w, point(i) );
    }
  }

  public def numRuns(): Long {
    return runIds.size();
  }

  public def runs( table: Tables ): ArrayList[Run] {
    val a = new ArrayList[Run]();
    for( runId in runIds ) {
      val run = table.runsTable.get( runId );
      a.add( run );
    }
    return a;
  }

  public def createRuns( table: Tables, numRuns: Long ): ArrayList[Run] {
    val a = new ArrayList[Run]();
    for( i in 1..numRuns ) {
      val run = new Run( table.maxRunId, this, table.maxRunId );
      // use run_id as seed value
      table.maxRunId += 1;
      table.runsTable.put( run.id, run );
      runIds.add( run.id );
      a.add( run );
    }
    return a;
  }

  public def createRunsUpTo( table: Tables, targetNumRuns: Long ): ArrayList[Run] {
    val n = ( numRuns() < targetNumRuns ) ? ( targetNumRuns - numRuns() ) : 0;
    return createRuns( table, n );
  }

  public def isFinished( table: Tables ): Boolean {
    for( run in runs( table ) ) {
      if( run.finished == false ) {
        return false;
      }
    }
    return true;
  }

  public def averagedResult( table: Tables ): Double {
    var sum: Double = 0.0;
    val runs = runs( table );
    for( run in runs ) {
      sum += run.result.normalize()(0);  // TODO: check other results
    }
    return sum / runs.size();
  }

  public def isSimilarToWithRespectTo( another: ParameterSet, axis: Long ): Boolean {
    val d = point - another.point;
    for( i in 0..(d.rank-1) ) {
      if( i != axis && d(i) != 0 ) {
        return false;
      }
    }
    return true;
  }

  static public def count( table: Tables ): Long {
    return table.psTable.size();
  }

  static public def countWhere( table: Tables , condition: (ParameterSet) => Boolean ): Long {
    var count: Long = 0;
    for( entry in table.psTable.entries() ) {
      val ps = entry.getValue();
      if( condition( ps ) ) {
        count += 1;
      }
    }
    return count;
  }

  static public def find( table: Tables, p: Point{self.rank==Simulator.numParams} ): ParameterSet {
    return table.psPointTable( p );
  }

  static public def findOrCreateParameterSet( table: Tables, p: Point{self.rank==Simulator.numParams} ): ParameterSet {
    var ps: ParameterSet = find( table, p );
    if( ps == null ) {
      ps = new ParameterSet( table.maxPSId, p );
      table.maxPSId += 1;
      table.psTable.put( ps.id, ps );
      table.psPointTable.put( ps.point, ps );
    }
    return ps;
  }
}

