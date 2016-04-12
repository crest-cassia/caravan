import x10.util.ArrayList;
import x10.io.File;
import caravan.Main;

class Dummy {

  static public def main( args: Rail[String] ) {
    if( args.size == 5 ) {
      val m = new Main();
      val numStaticTasks = Long.parse( args(0) );
      val sleepMu = Double.parse( args(1) );
      val sleepSigma = Double.parse( args(2) );
      val timeOut = Long.parse( args(3) ) * 1000;
      val numProcPerBuf = Long.parse( args(4) );
      val engine = new DummySearchEngine( numStaticTasks, 0, 0.25, 4, sleepMu, sleepSigma );
      m.run( engine, 300000, timeOut, numProcPerBuf );
    }
    else if( args.size == 7 ) {
      val m = new Main();
      val numStaticTasks = Long.parse( args(0) );
      val sleepMu = Double.parse( args(1) );
      val sleepSigma = Double.parse( args(2) );
      val timeOut = Long.parse( args(3) ) * 1000;
      val numProcPerBuf = Long.parse( args(4) );
      val psJson = args(5);
      val runJson = args(6);
      val engine = new DummySearchEngine( numStaticTasks, 0, 0.25, 4, sleepMu, sleepSigma );
      m.restart( psJson, runJson, engine, 300000, timeOut, numProcPerBuf );
    }
    else {
      Console.ERR.println("Usage: ./a.out <numStaticTasks> <sleepMu> <sleepSigma> <timeOut> <numProcPerBuf> [psJSON] [runJSON]");
    }
  }
}

