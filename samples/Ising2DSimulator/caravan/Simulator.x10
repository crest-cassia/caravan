package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;
import caravan.util.JSON;

@NativeCPPInclude("main.hpp")

public class Simulator {

  static struct InputParameters( beta: Double, h: Double, l: Long ) {
    public def toString(): String {
      return "{ \"beta\": " + beta + ", \"h\": " + h + ", \"l\": " + l + " }";
    }

    public def toJson(): String {
      return toString();
    }
  }

  static struct OutputParameters( orderParameter: Double ) {

    static def loadJSON( json: JSON.Value ): OutputParameters {
      val op = json(0).toDouble();
      return OutputParameters( op );
    }

    public def toString(): String {
      return "[" + orderParameter + "]";
    }

    public def normalize(): Rail[Double]{self.size==numOutputs} {
      val r = new Rail[Double](numOutputs);
      r(0) = orderParameter * 2.0 - 1.0;
      return r;
    }
  }

  static def run( params: InputParameters, seed: Long ): OutputParameters {
    val result = runSimulator( params.l-1, params.l, params.beta, params.h, seed );
    return OutputParameters( result );
  }

  @Native("c++", "RunSimulator( #1, #2, #3, #4, 128, 512, #5)")
  native static def runSimulator( lx: Long, ly: Long, beta: Double, h: Double, seed: Long ): Double;

  public static val numParams = 3;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val beta = point(0) * 0.01;
    val h    = point(1) * 0.01;
    val l   = point(2) * 10;
    return InputParameters( beta, h, l );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 20..50, -100..100, 4..6 );
  }

}

