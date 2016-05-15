package caravan;

import caravan.Tables;
import caravan.Run;
import caravan.ParameterSet;
import caravan.SearchEngines.ComprehensiveSearcher;

class ComprehensiveSearcherTest {

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
    val engine = new ComprehensiveSearcher( num_runs );
    p("constructor accepts num_runs: 1 = " + engine.targetNumRuns );
  }

  static public def testCreateInitialTask(): void {
    val num_runs = 3;
    val engine = new ComprehensiveSearcher( num_runs );
    val table = new Tables();

    val tasks = engine.createInitialTask( table, Simulator.searchRegion() );
    p("#createInitialTask creates tasks: 7623 = " + tasks.size() );
    val ps = ParameterSet.find( table, Point.make(0,0,10) );
    p("  each PS has 3 runs: " + ps.runs(table).size() );
  }

  static public def testOnParameterSetFinished(): void {
    val num_runs = 1;
    val engine = new ComprehensiveSearcher( num_runs );
    val table = new Tables();

    val ini_tasks = engine.createInitialTask( table, Simulator.searchRegion() );
    
    val ps = ParameterSet.find( table, Point.make(0,0,10) );
    for( run in ps.runs(table) ) {
      run.storeResult( SimulationOutput([0.0 as Double]), 0, 100, 200 );
    }

    val tasks = engine.onParameterSetFinished( table, ps );
    p("#onParameterSetFinished does not create tasks: [] = " + tasks );
  }
}

