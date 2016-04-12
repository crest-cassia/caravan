package caravan;

import x10.util.ArrayList;
import x10.util.HashMap;
import x10.io.File;
import caravan.util.JSON;

public class Tables {
  public val runsTable: HashMap[Long,Run];
  public val psTable: HashMap[Long,ParameterSet];
  var maxRunId: Long = 0;
  var maxPSId: Long = 0;

  def this() {
    runsTable = new HashMap[Long, Run]();
    psTable = new HashMap[Long, ParameterSet]();
  }

  def load( psJsonFile: String, runJsonFile: String ) {
    val psJson = JSON.parse( new File(psJsonFile) );
    val runJson = JSON.parse( new File(runJsonFile) );

    for( i in 0..(psJson.size()-1) ) {
      val ps = ParameterSet.loadJSON( psJson(i) );
      psTable.put( ps.id, ps );
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

    Console.OUT.println( runsJson() );
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
}

