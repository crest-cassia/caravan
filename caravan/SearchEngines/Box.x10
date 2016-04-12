package caravan.SearchEngines;

import x10.io.Console;
import x10.util.HashMap;
import x10.util.ArrayList;
import x10.regionarray.Region;

import caravan.*;

public class Box( region: Region{self.rank==Simulator.numParams} ) {
  public val psIds: ArrayList[Long] = new ArrayList[Long]();
  public var divided: Boolean = false;

  def toString(): String {
    val str = "{ " +
               " region: " + region + "," +
               " psIds: " + psIds +
               " }";
    return str;
  }

  def toRanges(): Rail[LongRange]{self.size==Simulator.numParams} {
    val init = (i: Long): LongRange => {
      val min = region.min(i);
      val max = region.max(i);
      val range = new LongRange( min, max );
      return range;
    };
    val ranges = new Rail[LongRange]( region.rank, init );
    return ranges;
  }

  def isFinished( table: Tables ): Boolean {
    for( ps in parameterSets( table ) ) {
      if( ps.isFinished( table ) == false ) {
        return false;
      }
    }
    return true;
  }

  def parameterSets( table: Tables ): ArrayList[ParameterSet] {
    val a = new ArrayList[ParameterSet]();
    for( psId in psIds ) {
      val ps = table.psTable( psId );
      a.add( ps );
    }
    return a;
  }

  def parameterSetsWhere( table: Tables, condition: (ParameterSet) => Boolean ) {
    val a = new ArrayList[ParameterSet]();
    for( psId in psIds ) {
      val ps = table.psTable( psId );
      if( condition( ps ) ) {
        a.add( ps );
      }
    }
    return a;
  }

  private def boundingPoints(): ArrayList[Point{self.rank==Simulator.numParams}] {
    val pointToRail = ( p: Point{self.rank==Simulator.numParams} ): Rail[Long]{self.size==Simulator.numParams} => {
      val r = new Rail[Long]( p.rank );
      for( i in 0..(p.rank-1) ) {
        r(i) = p(i);
      }
      return r;
    };

    var points: ArrayList[Point{self.rank==Simulator.numParams}] = new ArrayList[Point{self.rank==Simulator.numParams}]();
    points.add( region.minPoint() );
    for( axis in 0..(region.rank-1) ) {
      val tmpPoints = new ArrayList[Point{self.rank==Simulator.numParams}]();
      for( point in points ) {
        val r = pointToRail( point );
        r( axis ) = region.min( axis );
        tmpPoints.add( Point.make(r) );
        r( axis ) = region.max( axis );
        tmpPoints.add( Point.make(r) );
      }
      points = tmpPoints;
    }

    return points;
  }

  def createParameterSets( table: Tables ): ArrayList[ParameterSet] {
    val newPS = new ArrayList[ParameterSet]();
    for( point in boundingPoints() ) {
      val ps = ParameterSet.findOrCreateParameterSet( table, point );
      psIds.add( ps.id );
      newPS.add( ps );
    }
    return newPS;
  }

  def createSubTasks( table: Tables, targetNumRuns: Long ): ArrayList[Task] {
    val newTasks = new ArrayList[Task]();
    val newPSs = createParameterSets( table );
    for( ps in newPSs ) {
      val newRuns = ps.createRunsUpTo( table, targetNumRuns );
      for( run in newRuns ) {
        newTasks.add( run.generateTask() );
      }
    }
    return newTasks;
  }
}

