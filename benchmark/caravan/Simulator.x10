package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.util.Random;
import caravan.SimulationOutput;

public class Simulator {

  public static struct InputParameters( mu: Double, sigma: Double, p3: Long ) {
    public def toString(): String {
      return "{ \"mu\": " + mu + ", \"sigma\": " + sigma + ", \"p3\": " + p3 + " }";
    }
  }

  static def run( params: InputParameters, seed: Long ): SimulationOutput {
    val rnd = new Random(seed);
    val dt = (rnd.nextDouble() * 2.0 - 1.0) * params.sigma;
    val t = (params.mu + dt) * 1000.0;
    System.sleep( t as Long );
    return SimulationOutput( [t as Double] );
  }

  public static val numParams = 3;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val mu   = point(0) * 0.1;
    val sigma= point(1) * 0.1;
    return InputParameters( mu, sigma , point(2) );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 0..1000, 0..1000, 0..65536);
  }

}

