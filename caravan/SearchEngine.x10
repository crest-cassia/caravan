package caravan;

import caravan.Task;

import x10.util.ArrayList;

public class SearchEngine {

  static val pidFilePointers: Rail[Long]; = new Rail[Long](3); // [pid, file pointer for reading, file pointer for writing]

  @Native("c++", "launchSubProcessWithPipes( #1, (long*) &((#2)->raw[0]) )")
  private native static def launchSubProcessWithPipes( argv: Rail[String], pid_fps: Rail[Long] ): Long;

  @Native("c++", "readLines( (FILE*)(#1) )")
  native static def readLines( fp_r: Long ): Rail[String];

  @Native("c++", "writeLines( (FILE*)(#1), #2 )")
  native static def writeLines( fp_w: Long, lines: Rail[String] ): void;

  public static def launchSearcher( argv: Rail[String] ): Long {
    return launchSubProcessWithPipes( argv, pidFilePointers );
  }

  public static def createInitialTasks(): ArrayList[Task] {
    val lines: Rail[String] = readLines( pidFilePointers[1] );
    val tasks = new ArrayList[Task]();
    for( l in lines ) {
      val task = parseLine(l);
      tasks.add(task);
    }
  }

  private static def parseLine( line: String ): Task {
  // IMPLEMENT ME
  }

  public static def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task];

}
