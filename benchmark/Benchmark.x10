import x10.util.ArrayList;
import x10.io.File;
import caravan.Administrator;

class Benchmark {

  static public def main( args: Rail[String] ) {
    if( args.size == 8 ) {
      val m = new Administrator();
      val numStaticJobs = Long.parse( args(0) );
      val numDynamicJobs = Long.parse( args(1) );
      val jobGenProb = Double.parse( args(2) );
      val numJobsPerGen = Long.parse( args(3) );
      val sleepMu = Double.parse( args(4) );
      val sleepSigma = Double.parse( args(5) );
      val timeOut = Long.parse( args(6) ) * 1000;
      val numProcPerBuf = Long.parse( args(7) );
      val dumpInterval = 300000;
      val engine = new BenchSearchEngine( numStaticJobs, numDynamicJobs, jobGenProb, numJobsPerGen, sleepMu, sleepSigma );
      m.run( engine, 300000, timeOut, numProcPerBuf );
    }
    else {
      Console.ERR.println("Usage:\n./a.out <numStaticJobs> <numDynamicJobs> <jobGenProb> <numJobsPerGen> <sleepMu> <sleepSigma> <timeOut> <numProcPerBuf>");
      Console.ERR.println("Example:\n./a.out 10 90 0.25 4 0.5 0.1 30 4");
    }
  }
}

