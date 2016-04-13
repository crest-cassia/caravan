package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;
import caravan.util.JSON;

@NativeCPPInclude("main.hpp")

public class Simulator {

  static struct InputParameters( aging: Double, p_ld: Double ) {
    public def toString(): String {
      return "{ \"aging\": " + aging + ", \"p_ld\": " + p_ld + " }";
    }

    public def toJson(): String {
      return toString();
    }
  }

  static struct OutputParameters( degree: Long ) {

    static def loadJSON( json: JSON.Value ): OutputParameters {
      val degree = json(0).toLong();
      return OutputParameters( degree );
    }

    public def toString(): String {
      return "[" + degree + "]";
    }

    public def normalize(): Rail[Double]{self.size==numOutputs} {
      val r = new Rail[Double](numOutputs);
      r(0) = (degree as Double) * 0.1;
      return r;
    }
  }

  static def run( params: InputParameters, seed: Long ): OutputParameters {
    val degree = runSimulator( params.p_ld, params.aging, seed );
    return OutputParameters( degree );
  }

  @Native("c++", "RunSimulator(2000, 0.05, 0.005, 1.0, 0.0, #1, #2, 0.01, 5000, #3)")
  native static def runSimulator( p_ld: Double, aging: Double, seed: Long ): Long;

  public static val numParams = 2;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val aging = point(0) * 0.01;
    val p_ld  = point(1) * 0.001;
    return InputParameters( aging, p_ld );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 80..100, 1..20 );
  }

  public static def main( args: Rail[String] ): void {
    Console.OUT.println("Simulator");
    Console.OUT.println("  #runSimulator");
    runSimulator( 1.0, 0.005, 1234 );
  }

}

