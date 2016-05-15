package caravan;

import caravan.Tables;
import caravan.Run;
import caravan.ParameterSet;
import caravan.SearchEngines.GridSearcher;

class GridSearcherTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> ComprehensiveSearcherTest");

    p(">>> #testConstructor");
    testConstructor();

    p(">>> #testCreateInitialTask");
    testCreateInitialTask();

    p(">>> #testOnParameterSetFinished");
    testOnParameterSetFinished();
  }

  static public def testConstructor(): void {
    val num_runs = 1;
    val diff = 4.0;
    val engine = new GridSearcher( diff, num_runs );
    p("constructor accepts numRuns: 1 = " + engine.targetNumRuns );
    p("constructor accepts expectedResultDiff: 4.0 = " + engine.expectedResultDiff );
  }

  static public def testCreateInitialTask(): void {
    val diff = 4.0;
    val num_runs = 1;
    val engine = new GridSearcher( diff, num_runs );
    val table = new Tables();

    val tasks = engine.createInitialTask( table, Simulator.searchRegion() );
    p("#createInitialTask creates tasks: 8 = " + tasks.size() );
    val psCount = ParameterSet.countWhere( table, (ps:ParameterSet):Boolean => {
      val p0 = ps.point(0);
      val p1 = ps.point(1);
      val p2 = ps.point(2);
      return ((p0 == 0 || p0 == 10) && (p1 == 0 || p1 == 10) && (p2 == 0 || p2 == 10));
      });
    p("  PS are created on vertices of searchRegion: 8 = " + psCount );
  }

  static public def testOnParameterSetFinished(): void {
    val diff = 15.0;
    val num_runs = 1;
    val engine = new GridSearcher( diff, num_runs );
    val table = new Tables();

    val ini_tasks = engine.createInitialTask( table, Simulator.searchRegion() );

    val ps = finishTaskOn( table, 0,0,0 );

    val tasks = engine.onParameterSetFinished( table, ps );
    p("#onParameterSetFinished does not create tasks: [] = " + tasks );

    finishTaskOn( table,  0, 0,10 );
    finishTaskOn( table,  0,10, 0 );
    finishTaskOn( table,  0,10,10 );
    finishTaskOn( table, 10, 0, 0 );
    finishTaskOn( table, 10, 0,10 );
    finishTaskOn( table, 10,10, 0 );
    val ps2 = finishTaskOn( table, 10,10,10 );

    val tasks2 = engine.onParameterSetFinished( table, ps );
    p("#onParameterSetFinished creates tasks when Box is finished");
    p("  : 4 tasks = " + tasks2.size() );
    val psCount = ParameterSet.countWhere( table, (ps:ParameterSet):Boolean => {
      return ps.point(2) == 5;
    });
    p("  4 ps are created on p(2)=5 : 4 = " + psCount );
  }

  static private def finishTaskOn( table:Tables, p1:Long, p2:Long, p3:Long ):ParameterSet {
    val ps = ParameterSet.find( table, Point.make(p1,p2,p3) );
    for( run in ps.runs(table) ) {
      if( run.finished == false ) {
        val result = SimulationOutput( [p1 + p2 + 2*p3 as Double] );
        val placeId = 0;
        val startAt = 100;
        val finishAt = 200;
        run.storeResult( result, placeId, startAt, finishAt );
      }
    }
    return ps;
  }
}

