package caravan;

import x10.io.File;
import x10.io.Printer;
import x10.io.FileReader;
import caravan.Tables;
import caravan.Run;
import caravan.ParameterSet;
import caravan.util.JSON;

class TablesTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> TablesTest");

    p(">>> #testJSON");
    testJSON();

    p(">>> #testBinaryDump");
    testBinaryDump();
  }

  static public def testJSON(): void {
    val table = new Tables();
    p("Initially #empty() should be true : " + table.empty() );

    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val ps2 = ParameterSet.findOrCreateParameterSet( table, Point.make([4, 500, 10]) );
    val ps3 = ParameterSet.findOrCreateParameterSet( table, Point.make([5, 500, 20]) );

    for( entry in table.psTable.entries() ) {
      val ps = entry.getValue();
      ps.createRunsUpTo( table, 2 );
    }
    p("#parameterSetsJson() dump PS in JSON: \n" + table.parameterSetsJson() );
    p("#runsJson() dump runs in JSON: \n" + table.runsJson() );

    val table2 = new Tables();
    val pssJson = JSON.parse( table.parameterSetsJson() );
    val runsJson = JSON.parse( table.runsJson() );
    table2.loadFromJsonValue( pssJson, runsJson );
    p("tables are restored by #load() method");
    p("  restored PS  : \n" + table2.parameterSetsJson() );
    p("  restored runs: \n" + table2.runsJson() );

    val tasks = table2.createTasksForUnfinishedRuns();
    p("#createTasksForUnfinishedRuns() creates tasks");
    p("  number of created runs should be 6 : " + tasks.size() );
  }

  static public def testBinaryDump(): void {
    val table = new Tables();

    val ps1 = ParameterSet.findOrCreateParameterSet( table, Point.make([3, 500, 10]) );
    val ps2 = ParameterSet.findOrCreateParameterSet( table, Point.make([4, 500, 10]) );
    val ps3 = ParameterSet.findOrCreateParameterSet( table, Point.make([5, 500, 20]) );

    for( entry in table.psTable.entries() ) {
      val ps = entry.getValue();
      ps.createRunsUpTo( table, 2 );
    }
    table.runsTable(1).storeResult( SimulationOutput([1.0 as Double]), 1, 123, 456);

    val f = new File("temp.bin");
    val printer = f.printer();
    table.writeBinary( printer );
    printer.flush();

    val reader = f.openRead();
    val table2 = Tables.loadFromBinary( reader );
    p("tables are restored by #loadFromBinary() method");
    p("  restored PS  : \n" + table2.parameterSetsJson() );
    p("  restored runs: \n" + table2.runsJson() );

    val tasks = table2.createTasksForUnfinishedRuns();
    p("#createTasksForUnfinishedRuns() creates tasks");
    p("  number of created runs should be 5 : " + tasks.size() );

    f.delete();
  }
}

