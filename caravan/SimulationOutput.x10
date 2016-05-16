package caravan;

import x10.io.Printer;
import x10.io.FileReader;
import x10.io.Marshal.DoubleMarshal;
import caravan.util.JSON;

public struct SimulationOutput( values: Rail[Double]{self.size==Simulator.numOutputs} ) {

  public def toString(): String {
    return values.toString();
  }

  public def writeBinary( w: Printer ): void {
    val marshalDouble = new DoubleMarshal();
    for( x in values ) {
      marshalDouble.write( w, x );
    }
  }

  public static def loadFromBinary( r: FileReader ): SimulationOutput {
    val marshalDouble = new DoubleMarshal();
    val result = new Rail[Double]( Simulator.numOutputs );
    for( i in 0..(result.size-1) ) {
      result(i) = marshalDouble.read( r );
    }
    return SimulationOutput( result );
  }

  static public def loadJSON( json: JSON.Value ): SimulationOutput {
    // TODO: IMPLEMENT ME
    return SimulationOutput( new Rail[Double](Simulator.numOutputs) );
  }
}

