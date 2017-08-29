package caravan;

import x10.io.File;
import x10.util.Timer;
import x10.util.ArrayList;

public struct Task( taskId: Long, argv: Rail[String] ) {

  private def system( argv: Rail[String] ): Long {
    // IMPLEMENT ME
    return 0;
  }

  public def run(): SimulationOutput {
    val rc = system( argv );
    if( rc != 0 ) {
      return SimulationOutput(rc, new Rail[Double]() );
    }
    return parseResults();
  }

  private def parseResults(): SimulationOutput {

    val results = new ArrayList[Double]();
  
    val f = new File( resultsFilePath() );
    for( line in f.lines() ) {
      val trimmed = line.trim();
      if( trimmed.length() > 0 ) {
        val d = Double.parse(trimmed);
        results.add(d);
      }
    }

    val so = SimulationOutput( 0, results.toRail() );
    return so;
  }

  private def resultsFilePath(): String {
    return String.format("_results_%08d.txt", [taskId as Any]);
  }
  
  public def toString(): String {
    return "{ taskId : " + taskId + ", argv : " + argv + " }";
  }
}

