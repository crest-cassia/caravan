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

  @Native("c++", "writeLines( (FILE*)(#1), #2 )")
  private native static def writeLines( fp_w: Long, lines: Rail[String] ): void;

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
    val parsed = line.split(" ");
    assert parsed.size > 1;
    val taskId = Long.parse( parsed(0) );
    val argv = new Rail[String]( parsed.size - 1 );
    for( i in 1..(parsed.size-1) ) {
      argv(i-1) = parsed(i);
    }
    return Task( taskId, argv );
  }

  private static def resultToLine( r: Result ): String {
    val s = String.format("%l %l ", [r.taskId, r.rc as Any] );
    var line: String = s;
    for( x in r.values ) {
      line += x.toString() + " ";
    }
    return line;
  }

  public static def onTasksFinished( results: Rail[Result] ): ArrayList[Task] {
    val lines: Rail[String] = new Rail[String](results.size+1);
    for( i in 0..(results.size-1) ) {
      val r = results(i);
      val line = resultToLine(r);
      lines(i) = line;
    }
    lines(results.size) = "";  // finish writing by entering an empty line
    writeLines( pidFilePointers(2), lines );

    return readTasks();
  }
}

