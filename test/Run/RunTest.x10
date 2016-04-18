package caravan;

import caravan.Run;
import caravan.ParameterSet;

class RunTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> RunTest");

    p(">>> #testFields");
    testFields();

    p(">>> #testParameterSet");
    testParameterSet();

    p(">>> #testStoreResult");
    testStoreResult();

  }

  static public def testFields(): void {
    val ps = new ParameterSet( 10, Point.make([3, 500]) );

    val run = new Run( 1, ps, 1234 );

    p( run );
  }

  static public def testStoreResult(): void {
    val ps = new ParameterSet( 10, Point.make([3, 500]) );

    val run = new Run( 1, ps, 1234 );
    val result = Simulator.OutputParameters( 3.5 );
    run.storeResult( result, 3, 1000, 2000 );

    p( run );
  }

  static public def testParameterSet(): void {
    val table = new Tables();
    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500]) );
    val ps2 = ParameterSet.findOrCreateParameterSet( table, Point.make([4, 500]) );
    val run1 = ps1.createRuns( table, 1 )(0);

    p( run1.parameterSet(table) );
  }
}

