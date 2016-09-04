package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.compiler.Native;
import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;

@NativeCPPInclude("main.hpp")

public class Simulator {

  static struct InputParameters( p1: Long, p2: Long, p3: Double ) {
    public def toString(): String {
      return "{ \"p1\": " + p1 + ", \"p2\": " + p2 + ", \"p3\": " + p3 + " }";
    }
  }

  static def run( params: InputParameters, seed: Long ): SimulationOutput {
    val result = runSimulator( params.p1, params.p2, params.p3, seed );
    return SimulationOutput( [result as Double] );
  }

  @Native("c++", "RunSimulator( #1, #2, #3, #4)")
  native static def runSimulator( p1: Long, p2: Long, p3: Double, seed: Long ): Double;

  public static val numParams = 3;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val p1 = point(0);
    val p2 = point(1);
    val p3 = point(2) * 0.2;
    return InputParameters( p1, p2, p3 );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 3..10, -20..20, 40..60 );
  }
}

