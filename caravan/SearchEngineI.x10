package caravan;

import caravan.Tables;
import caravan.Simulator;
import caravan.ParameterSet;
import caravan.Run;
import caravan.Task;

import x10.util.ArrayList;
import x10.regionarray.Region;

public interface SearchEngineI {

  public def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task];

  public def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task];

}
