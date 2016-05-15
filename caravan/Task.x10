package caravan;

import x10.io.File;
import x10.util.Timer;
import caravan.SimulationOutput;

public struct Task( runId: Long, params: Simulator.InputParameters, seed: Long) {

  public def run(): SimulationOutput {
    val result = Simulator.run( params, seed );
    return result;
  }
  
  public def toString(): String {
    return "{ runId : " + runId + ", params : " + params + ", seed: " + seed + " }";
  }
}
