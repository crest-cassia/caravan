package caravan;

import x10.io.File;
import x10.util.Timer;

public struct Task( taskId: Long, argv: Rail[String] ) {

  public def run(): SimulationOutput {
    val err = system( argv );
    if( err != 0 ) {
      return SimulationOutput( [] )
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

    val so = SimulationOutput( results.toRail() );
    return so;
  }

  private def resultsFilePath(): String {
    return String.format("_results_%08d.txt", [taskId as Any]);
  }
  
  public def toString(): String {
    return "{ runId : " + runId + ", argv : " + argv + " }";
  }
}

