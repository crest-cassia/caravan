package caravan;

import caravan.util.JSON;

public struct SimulationOutput( values: Rail[Double]{self.size==Simulator.numOutputs} ) {

  public def toString(): String {
    return values.toString();
  }

  static public def loadJSON( json: JSON.Value ): SimulationOutput {
    // TODO: IMPLEMENT ME
    return SimulationOutput( new Rail[Double](Simulator.numOutputs) );
  }
}

