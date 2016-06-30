package caravan;

import x10.util.ArrayList;
import x10.util.HashMap;
import x10.io.File;
import x10.io.Printer;
import x10.io.FileReader;
import x10.io.Marshal.LongMarshal;

import caravan.util.JSON;

public class Tables {
  public val runsTable: HashMap[Long,Run];
  public val psTable: HashMap[Long,ParameterSet];
  public val psPointTable: HashMap[ Point{self.rank==Simulator.numParams}, ParameterSet];
  var maxRunId: Long = 0;
  var maxPSId: Long = 0;

  def this() {
    runsTable = new HashMap[Long, Run]();
    psTable = new HashMap[Long, ParameterSet]();
    psPointTable = new HashMap[ Point{self.rank==Simulator.numParams}, ParameterSet]();
  }

  def load( psJsonFile: String, runJsonFile: String ):void {
    val psJson = JSON.parse( new File(psJsonFile) );
    val runJson = JSON.parse( new File(runJsonFile) );
    loadFromJsonValue( psJson, runJson );
  }

  def loadFromJsonValue( psJson: JSON.Value, runJson:JSON.Value ):void {
    for( i in 0..(psJson.size()-1) ) {
      val ps = ParameterSet.loadJSON( psJson(i) );
      psTable.put( ps.id, ps );
      psPointTable.put( ps.point, ps );
      if( ps.id+1 > maxPSId ) {
        maxPSId = ps.id + 1;
      }
    }
    for( i in 0..(runJson.size()-1) ) {
      val run = Run.loadJSON( runJson(i), this );
      runsTable( run.id ) = run;
      if( run.id+1 > maxRunId ) {
        maxRunId = run.id + 1;
      }
      run.parameterSet( this ).runIds.add( run.id );
    }
  }

  def empty(): Boolean {
    return (runsTable.size() == 0);
  }

  def runsJson(): String {
    var json:String = "[\n";
    for( entry in runsTable.entries() ) {
      val run = entry.getValue();
      json += run.toJson() + ",\n";
    }
    val s = json.substring( 0n, json.length()-2n ) + "\n]";
    return s;
  }

  def parameterSetsJson(): String {
    var json: String = "[\n";
    for( entry in psTable.entries() ) {
      val ps = entry.getValue();
      json += ps.toJson() + ",\n";
    }
    val s = json.substring( 0n, json.length()-2n ) + "\n]";
    return s;
  }

  public def writeBinary( w: Printer ): void {
    val marshalLong = new LongMarshal();

    // writing Simulator info
    marshalLong.write( w, Simulator.numParams );
    marshalLong.write( w, Simulator.numOutputs );

    // writing PS
    marshalLong.write( w, psTable.size() );
    for( entry in psTable.entries() ) {
      val ps = entry.getValue();
      ps.writeBinary( w );
    }

    // writing Runs
    marshalLong.write( w, runsTable.size() );
    for( entry in runsTable.entries() ) {
      val run = entry.getValue();
      run.writeBinary( w );
    }
  }

  private def readBinary( r: FileReader ): void {
    val marshalLong = new LongMarshal();

    val numParams = marshalLong.read( r );
    assert (numParams == Simulator.numParams);
    val numOutputs = marshalLong.read( r );
    assert (numOutputs == Simulator.numOutputs);

    // loading PS
    val psSize = marshalLong.read( r );
    for( i in 0..(psSize-1) ) {
      val ps = ParameterSet.loadFromBinary( r );
      psTable.put( ps.id, ps );
      psPointTable.put( ps.point, ps );
      if( ps.id+1 > maxPSId ) {
        maxPSId = ps.id + 1;
      }
    }

    // loading Runs
    val runSize = marshalLong.read( r );
    for( i in 0..(runSize-1) ) {
      val run = Run.loadFromBinary( r, this );
      runsTable( run.id ) = run;
      if( run.id+1 > maxRunId ) {
        maxRunId = run.id + 1;
      }
      run.parameterSet( this ).runIds.add( run.id );
    }
  }

  public static def loadFromBinary( r: FileReader ): Tables {
    val table = new Tables();
    table.readBinary( r );
    return table;
  }

  def createTasksForUnfinishedRuns(): ArrayList[Task] {
    val tasks = new ArrayList[Task]();
    for( entry in runsTable.entries() ) {
      val run = entry.getValue();
      if( run.unfinished() ) {
        tasks.add( run.generateTask() );
      }
    }
    return tasks;
  }

  def numUnfinishedRuns(): Long {
    var count:Long = 0;
    for( entry in runsTable.entries() ) {
      val run = entry.getValue();
      if( run.unfinished() ) {
        count += 1;
      }
    }
    return count;
  }
}

