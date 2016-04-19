package caravan;

import caravan.Run;
import caravan.ParameterSet;
import caravan.util.JSON;

class ParameterSetTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> ParameterSetTest");

    p(">>> #testFields");
    testFields();

    p(">>> #testToJSON");
    testToJSON();

    p(">>> #testLoadJSON");
    testLoadJSON();

    p(">>> #testRuns");
    testRuns();

    p(">>> #testIsFinished");
    testIsFinished();

    p(">>> #testAveragedResult");
    testAveragedResult();

    p(">>> #testIsSimilarToWithRespectTo");
    testIsSimilarToWithRespectTo();

    p(">>> #testCountWhere");
    testCountWhere();

    p(">>> #testFind");
    testFind();
  }

  static public def testFields(): void {
    val ps = new ParameterSet( 10, Point.make([3, 500, 10]) );
    p( ps );
  }

  static public def testToJSON(): void {
    val ps = new ParameterSet( 10, Point.make([3, 500, 10]) );
    p( ps.toJson() );
  }

  static public def testLoadJSON(): void {
    val str = "{ \"id\": 1234, \"point\": [2,120,10], \"params\": [2, 1.2, 1.0] }";
    val json = JSON.parse( str );
    val ps = ParameterSet.loadJSON( json );
    p( ps );
  }

  static public def testRuns(): void {
    val table = new Tables();
    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val runs = ps1.createRuns( table, 3 );

    p("numRuns should be 3 : " + ps1.numRuns() );
    p("there are three runs: \n  " + ps1.runs( table ) );

    ps1.createRunsUpTo( table, 5 );
    p("numRuns should be 5 : " + ps1.numRuns() );

    val empty_runs = ps1.createRunsUpTo( table, 5 ); // to test no run is created
    p("numRuns should be 5 : " + ps1.numRuns() );
    p("empty_runs should be empty ArrayList : " + empty_runs );
  }

  static public def testIsFinished(): void {
    val table = new Tables();
    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val runs = ps1.createRuns( table, 3 );

    p("isFinished is false initially: " + ps1.isFinished( table ) );

    runs(0).storeResult( Simulator.OutputParameters(0.5), 3, 1000, 2000 );
    runs(1).storeResult( Simulator.OutputParameters(0.5), 3, 1000, 2000 );

    p("isFinished is false if there remains unfinished run: " + ps1.isFinished( table ) );

    runs(2).storeResult( Simulator.OutputParameters(0.5), 3, 1000, 2000 );

    p("isFinished is true when all runs are finished: " + ps1.isFinished( table ) );
  }

  static public def testAveragedResult(): void {
    val table = new Tables();
    val ps = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val runs = ps.createRuns( table, 3 );

    runs(0).storeResult( Simulator.OutputParameters(1.0), 3, 1000, 2000 );
    runs(1).storeResult( Simulator.OutputParameters(1.5), 3, 1000, 2000 );
    runs(2).storeResult( Simulator.OutputParameters(2.0), 3, 1000, 2000 );

    p("averagedResult should be 1.5: "+ ps.averagedResult( table ) );
  }

  static public def testIsSimilarToWithRespectTo(): void {
    val ps1 = new ParameterSet( 1, Point.make([3, 500, 10]) );
    val ps2 = new ParameterSet( 2, Point.make([3, 500, 20]) );
    val ps3 = new ParameterSet( 3, Point.make([3, 400, 20]) );

    val b1 = ps1.isSimilarToWithRespectTo( ps2, 2 );
    p("is true when axis0 and 1 are same: " + b1 );

    val b2 = ps1.isSimilarToWithRespectTo( ps2, 1 );
    p("is false when either axis0 or 2 is different : " + b2 );

    val b3 = ps1.isSimilarToWithRespectTo( ps3, 2 );
    p("is false when coordinates are different on more than two axes : " + b3 );
  }

  static public def testCountWhere(): void {
    val table = new Tables();
    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val ps2 = ParameterSet.findOrCreateParameterSet( table, Point.make([4, 500, 10]) );
    val ps3 = ParameterSet.findOrCreateParameterSet( table, Point.make([5, 500, 20]) );

    val n1 = ParameterSet.count( table );
    p("count All should be 3: " + n1 );

    val n2 = ParameterSet.countWhere( table, (ps:ParameterSet) => {
      return ps.point(0) == 3;
    });
    p("count where point(0)=3 should be 1 : " + n2 );

    val n3 = ParameterSet.countWhere( table, (ps:ParameterSet) => {
      return (ps.point(0) > 3 && ps.point(2) >= 10);
    });
    p("count where point(0)>3 and point(2)>=10 shoud be 2 : " + n3 );
  }

  static public def testFind(): void {
    val table = new Tables();
    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val ps2 = ParameterSet.findOrCreateParameterSet( table, Point.make([4, 500, 10]) );
    val ps3 = ParameterSet.findOrCreateParameterSet( table, Point.make([5, 500, 20]) );

    val found = ParameterSet.find( table, Point.make([4,500,10]) );
    p("found PS should have point[4,500,10]: " + found.point );
    p("     and should have id 1 : " + found.id );

    val not_found = ParameterSet.find( table, Point.make([0,1,2]) );
    p("when matched PS is not found, it should return null : " + not_found );

    val ps4 = ParameterSet.findOrCreateParameterSet( table, Point.make([5, 500, 20]) );
    p("when identical PS exists, findOrCreateParameterSet does not create a new PS");
    p("  ps4.id should be 2: " + ps4.id);
    p("  ParameterSet.count should be 3: " + ParameterSet.count( table) );

  }
}

