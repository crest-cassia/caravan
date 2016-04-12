package caravan.SearchEngines;
import x10.util.ArrayList;
import x10.regionarray.Region;

import caravan.*;

public class GridSearcher implements SearchEngineI {

  val boxes: ArrayList[Box];
  val targetNumRuns = 1;
  val expectedResultDiff = 0.1;

  public def this() {
    boxes = new ArrayList[Box]();
  }

  def d( o: Any ): void {
    Console.ERR.println(o);
    // TODO: IMPLEMENT ME
  }

  public def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task] {
    val box = new Box( searchRegion );
    boxes.add( box );
    return box.createSubTasks( table, targetNumRuns );
  }

  public def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task] {
    val newTasks: ArrayList[Task] = new ArrayList[Task]();
    val appendTask = ( toAdd: ArrayList[Task] ) => {
      for( task in toAdd ) {
        newTasks.add( task );
      }
    };
    val boxes = findBoxesFromPS( finishedPS );
    for( box in boxes ) {
      if( box.divided == false && box.isFinished( table ) == true ) {
        d("  dividing box " + box );
        val tasks = divideBox( table, box );
        appendTask( tasks );
      }
    }
    d("  onPSFinished#newTasks: " + newTasks );
    return newTasks;
  }

  private def findBoxesFromPS( ps: ParameterSet ): ArrayList[Box] {
    val ret = new ArrayList[Box]();
    for( box in boxes ) {
      if( box.psIds.contains( ps.id ) ) {
        ret.add( box );
      }
    }
    return ret;
  }

  private def diffResults( table: Tables, parameterSets: ArrayList[ParameterSet] ): Double {
    assert parameterSets.size() == 2;
    val r0 = parameterSets(0).averagedResult( table );
    val r1 = parameterSets(1).averagedResult( table );
    d( "  diffResults of " + parameterSets + " = " + Math.abs(r0-r1) );
    return Math.abs( r0 - r1 );
  }

  // return true if box needs to be divided in the direction of axis
  private def needToDivide( table: Tables, box: Box, axis: Long ): Boolean {
    if( box.region.projection( axis ).size() <= 2 ) {
      return false;
    }

    var maxDiff: Double = 0.0;

    val arraySmallerPS = box.parameterSetsWhere( table, (ps: ParameterSet) => {
      return ps.point( axis ) == box.region.min( axis );
    });
    for( smallerPS in arraySmallerPS ) {
      val psPairToCompare = box.parameterSetsWhere( table, (ps: ParameterSet) => {
        return ps.isSimilarToWithRespectTo( smallerPS, axis );
      });
      val diff = diffResults( table, psPairToCompare );
      if( diff > maxDiff ) {
        maxDiff = diff;
      }
    }

    d( "  resultDiff of Box(" + box + ") in " + axis + " direction: " + maxDiff );

    return maxDiff > expectedResultDiff;
  }

  private def divideBoxIn( box: Box, axis: Long ): ArrayList[Box] {
    val ranges = box.toRanges();
    val min = ranges( axis ).min;
    val max = ranges( axis ).max;
    val mid = (min + max) / 2;

    ranges(axis) = min..mid;
    val newRegion1 = Region.makeRectangular( ranges );
    val newBox1 = new Box( newRegion1 );

    ranges(axis) = mid..max;
    val newRegion2 = Region.makeRectangular( ranges );
    val newBox2 = new Box( newRegion2 );

    val boxes = new ArrayList[Box]();
    boxes.add( newBox1 );
    boxes.add( newBox2 );
    return boxes;
  }

  private def divideBox( table: Tables, box: Box ): ArrayList[Task] {
    var boxesToBeDivided: ArrayList[Box] = new ArrayList[Box]();
    boxesToBeDivided.add( box );

    val newBoxes = new ArrayList[Box]();
    for( axis in 0..(box.region.rank-1) ) {
      val bDivide = needToDivide( table, box, axis );
      if( bDivide ) {
        d( "  dividing in " + axis + " direction : " + boxesToBeDivided );
        newBoxes.clear();
        for( boxToBeDivided in boxesToBeDivided ) {
          val dividedBoxes = divideBoxIn( boxToBeDivided, axis );
          boxToBeDivided.divided = true;
          newBoxes.addAll( dividedBoxes );
        }
        boxesToBeDivided = newBoxes.clone();
      }
    }
    d( "  newBoxes: " + newBoxes );

    val newTasks = new ArrayList[Task]();
    for( newBox in newBoxes ) {
      val tasks = newBox.createSubTasks( table, targetNumRuns );
      for( task in tasks ) {
        newTasks.add( task );
      }
      boxes.add( newBox );
    }

    box.divided = true;

    d( "newTasks : " + newTasks );

    return newTasks;
  }
}

