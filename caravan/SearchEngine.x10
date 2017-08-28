package caravan;

import caravan.Simulator;
import caravan.Task;

import x10.util.ArrayList;
import x10.regionarray.Region;

public class SearchEngine {

  static val pidFilePointers: Rail[Long]; = new Rail[Long](3);

  @Native("c++", "launchSubProcessWithPipes( #1, (long*) &((#2)->raw[0]) )")
  private native static def launchSubProcessWithPipes( argv: Rail[String], pid_fps: Rail[Long] );

  public static def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task] {
    fpsPid: Rail[Long] = new Rail[Long](3);
    launchSubProcessWithPipes( argv, pidFilePointers );
    readTasks( 
  }


  public static def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task];

}
