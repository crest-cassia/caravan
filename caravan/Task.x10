package caravan;

import x10.io.File;
import x10.util.Timer;
import x10.util.ArrayList;
import x10.compiler.Native;

public struct Task( taskId: Long, argv: Rail[String] ) {

  @Native("c++", "system( (#1)->c_str() );")
  private native static def system( cmd:String ):Int;

  public def run(): Result {
    var cmd: String = "";
    for( arg in argv ) { cmd += arg + " "; }
    val rc = system( cmd );
    if( rc != 0n ) {
      return Result(taskId, rc as Long, new Rail[Double]() );
    }
    return parseResults();
  }

  private def parseResults(): Result {

    val results = new ArrayList[Double]();
  
    val f = new File( resultsFilePath() );
    for( line in f.lines() ) {
      val trimmed = line.trim();
      if( trimmed.length() > 0 ) {
        val d = Double.parse(trimmed);
        results.add(d);
      }
    }

    val so = Result(taskId, 0, results.toRail() );
    return so;
  }

  public def resultsFilePath(): String {
    return String.format("_results_%08d.txt", [taskId as Any]);
  }
  
  public def toString(): String {
    return "{ taskId : " + taskId + ", argv : " + argv + " }";
  }
}

