package caravan;

import x10.util.ArrayList;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;

@NativeCPPInclude("SubProcess.hpp")
@NativeCPPCompilationUnit("SubProcess.cpp")

public class SearchEngine {

  static public val pidFilePointers: Rail[Long] = new Rail[Long](3); // [pid, file pointer for reading, file pointer for writing]

  @Native("c++", "launchSubProcessWithPipes( #1, (long*) &((#2)->raw[0]) )")
  private native static def launchSubProcessWithPipes( argv: Rail[String], pid_fps: Rail[Long] ): Long;

  @Native("c++", "readLinesUntilEmpty( (FILE*)(#1) )")
  private native static def readLinesUntilEmpty( fp_r: Long ): Rail[String];

  @Native("c++", "writeLine( (FILE*)(#1), #2 )")
  private native static def writeLine( fp_w: Long, line: String ): void;

  public static def launchSearcher( argv: Rail[String] ): Long {
    return launchSubProcessWithPipes( argv, pidFilePointers );
  }

  public static def createInitialTasks(): ArrayList[Task] {
    return readTasks();
  }

  private static def readTasks(): ArrayList[Task] {
    val lines: Rail[String] = readLinesUntilEmpty( pidFilePointers(1) );
    val tasks = new ArrayList[Task]();
    for( l in lines ) {
      val task = parseLine(l);
      tasks.add(task);
    }
    return tasks;
  }

  private static def parseLine( line: String ): Task {
    val split_at = line.indexOf(" ") as Int;
    assert split_at > 0;
    val taskId = Long.parse( line.substring(0n,split_at) );
    val cmd = line.substring(split_at+1n);
    return Task( taskId, cmd );
  }

  public static def sendResult( resultLine: String ): ArrayList[Task] {
    writeLine( pidFilePointers(2), resultLine );
    return readTasks();
  }
}

