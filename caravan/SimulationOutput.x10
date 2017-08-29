package caravan;

import x10.io.Printer;
import x10.io.FileReader;
import x10.io.Marshal.DoubleMarshal;
import caravan.util.JSON;

public struct SimulationOutput( rc: Long, values: Rail[Double] ) {

  public def toString(): String {
    return values.toString();
  }
}

