package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;
import caravan.util.JSON;

@NativeCPPInclude("main.hpp")

public class Simulator {

  static struct InputParameters( x1: Double, x2: Double, x3: Double ) {
    public def toString(): String {
      return "{ \"x1\": " + x1 + ", \"x2\": " + x2 + ", \"x3\": " + x3 + " }";
    }

    public def toJson(): String {
      return toString();
    }
  }

  static struct OutputParameters( result: Double ) {

    static def loadJSON( json: JSON.Value ): OutputParameters {
      val result = json(0).toDouble();
      return OutputParameters( result );
    }

    public def toString(): String {
      return "[" + result + "]";
    }

    public def normalize(): Rail[Double]{self.size==numOutputs} {
      val r = new Rail[Double](numOutputs);
      r(0) = result;
      return r;
    }
  }

  static def run( params: InputParameters, seed: Long ): OutputParameters {
    val result = runSimulator( params.x1, params.x2, params.x3 );
    return OutputParameters( result );
  }

  @Native("c++", "RunSimulator( #1, #2, #3 )")
  native static def runSimulator( x1: Double, x2: Double, x3: Double ): Double;

  public static val numParams = 3;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val x1 = Math.PI * ( 2.0 * point(0) / 10000.0 - 1.0 );
    val x2 = Math.PI * ( 2.0 * point(1) / 10000.0 - 1.0 );
    val x3 = Math.PI * ( 2.0 * point(2) / 10000.0 - 1.0 );
    return InputParameters( x1, x2, x3 );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 0..10000, 0..10000, 0..10000 );
  }

}

