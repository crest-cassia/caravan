package caravan.SearchEngines;

import x10.util.ArrayList;
import x10.regionarray.Region;

public class ComprehensiveSearcher implements SearchEngineI {

  val targetNumRuns = 1;

  def this() {
  }

  public def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task] {
    val newTasks = new ArrayList[Task]();
    for( point in searchRegion ) {
      val ps = ParameterSet.findOrCreateParameterSet( table, point );
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

