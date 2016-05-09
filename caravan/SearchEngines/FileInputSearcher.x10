package caravan.SearchEngines;

import x10.util.ArrayList;
import x10.regionarray.Region;
import x10.util.RailUtils;
import x10.io.File;

import caravan.*;

public class FileInputSearcher implements SearchEngineI {

  val inputFileName: String;
  val targetNumRuns: Long;

  public def this( _inputFileName: String, _targetNumRuns: Long ) {
    inputFileName = _inputFileName;
    targetNumRuns = _targetNumRuns;
  }

  public def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task] {
    val newTasks = new ArrayList[Task]();

    Console.ERR.println("loading " + inputFileName);
    val input = new File(inputFileName);
    val psidsOut = new File("ps_ids.txt").printer();
    for( line in input.lines() ) {
      // Console.ERR.println( "line: " + line );
      val a: Rail[String]{self.size==Simulator.numParams} = line.split(" ") as Rail[String]{self.size==Simulator.numParams};
      val c: Rail[Long]{self.size==Simulator.numParams} = new Rail[Long]( a.size );
      for( i in 0..(a.size-1) ) {
        val d = Double.parse( a(i) );
        val min = searchRegion.min( i );
        val max = searchRegion.max( i );
        c(i) = Math.round(d * (max-min) + min) as Long;
      }
      val point: Point{self.rank==Simulator.numParams} = Point.make(c);
      val ps = ParameterSet.findOrCreateParameterSet( table, point );
      psidsOut.println(ps.id);
      val runs = ps.createRunsUpTo( table, targetNumRuns );
      for( run in runs ) {
        newTasks.add( run.generateTask() );
      }
    }
    return newTasks;
  }

  public def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task] {
    val empty = new ArrayList[Task]();
    return empty;
  }
}

