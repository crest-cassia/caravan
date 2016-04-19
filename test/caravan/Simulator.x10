package caravan;

import x10.regionarray.Region;
import x10.io.File;
import x10.util.Random;
import caravan.util.JSON;

public class Simulator {

  public static struct InputParameters( p1: Long, p2: Double, p3: Double ) {
    public def toString(): String {
      return "{ \"p1\": " + p1 + ", \"p2\": " + p2 + ", \"p3\": " + p3 +" }";
    }

    public def toJson(): String {
      return toString();
    }
  }

  public static struct OutputParameters( r1: Double ) {

    static def loadJSON( json: JSON.Value ): OutputParameters {
      val r1 = json(0).toDouble();
      return OutputParameters( r1 );
    }

    public def toString(): String {
      return "[" + r1 + "]";
    }

    public def normalize(): Rail[Double]{self.size==numOutputs} {
      val r = new Rail[Double](numOutputs);
      r(0) = r1;
      return r;
    }
  }

  static def run( params: InputParameters, seed: Long ): OutputParameters {
    val rnd = new Random(seed);
    val r1 = params.p1 + params.p2 + rnd.nextDouble();
    return OutputParameters( r1 );
  }

  public static val numParams = 3;
  public static val numOutputs = 1;

  static def deregularize( point: Point{self.rank==numParams} ): InputParameters {
    val p1 = point(0) * 1;
    val p2 = point(1) * 0.01;
    val p3 = point(1) * 0.1;
    return InputParameters( p1, p2, p3 );
  }

  static def searchRegion(): Region{self.rank==numParams} {
    return Region.makeRectangular( 0..10, 0..1000, 10..30 );
  }
}

