import x10.util.ArrayList;
import x10.regionarray.Region;
import x10.util.Random;

import caravan.SearchEngineI;
import caravan.Task;
import caravan.Tables;
import caravan.ParameterSet;
import caravan.Run;
import caravan.Simulator;

public class DummySearchEngine implements SearchEngineI {

  val numStaticJobs: Long;
  val numDynamicJobs: Long;
  val jobGenProb: Double;
  val numJobsPerGen: Long;
  val mu: Double;
  val sigma: Double;
  val muLong: Long;
  val sigmaLong: Long;

  val rnd: Random;

  var psCount: Long = 0;

  def this( _numStaticJobs: Long, _numDynamicJobs: Long, _jobGenProb: Double, _numJobsPerGen: Long,
            _mu: Double, _sigma: Double ) {
    numStaticJobs = _numStaticJobs;
    numDynamicJobs = _numDynamicJobs;
    jobGenProb = _jobGenProb;
    numJobsPerGen = _numJobsPerGen;
    mu = _mu;
    sigma = _sigma;
    muLong = (mu * 10.0) as Long;
    sigmaLong = (sigma * 10.0) as Long;

    rnd = new Random( 0 );
  }

  private def createNewTask( table: Tables, num: Long ): ArrayList[Task] {
    val tasks = new ArrayList[Task]();
    for( i in 0..(num-1) ) {
      val point = Point.make( muLong, sigmaLong, psCount );
      val ps = ParameterSet.findOrCreateParameterSet( table, point );
      val runs = ps.createRunsUpTo( table, 1 );
      for( run in runs ) {
        tasks.add( run.generateTask() );
      }
      psCount += 1;
    }
    return tasks;
  }

  public def createInitialTask( table: Tables, searchRegion: Region{self.rank==Simulator.numParams} ): ArrayList[Task] {
    return createNewTask( table, numStaticJobs );
  }

  public def onParameterSetFinished( table: Tables, finishedPS: ParameterSet ): ArrayList[Task] {
    val numRunningPS = ParameterSet.countWhere( table, (ps:ParameterSet):Boolean => { return !ps.isFinished(table); } );
    Console.ERR.println("on PS finished: " + numRunningPS);
    if( rnd.nextDouble() < jobGenProb || numRunningPS == 0 ) {
      val numTodo = numStaticJobs + numDynamicJobs - ParameterSet.count( table );
      val numTasks = numTodo > numJobsPerGen ? numJobsPerGen : numTodo;
      return createNewTask( table, numTasks );
    }
    else {
      return new ArrayList[Task]();
    }
  }
}

