package caravan;

import x10.io.File;
import x10.util.Timer;
import x10.util.ArrayList;
import x10.util.Pair;
import x10.compiler.Native;

import x10.compiler.NativeCPPInclude;
import x10.compiler.NativeCPPCompilationUnit;

@NativeCPPInclude("SubProcess.hpp")
@NativeCPPCompilationUnit("SubProcess.cpp")

public struct Task( taskId: Long, cmd: String ) {

  @Native("c++", "chdir( (#1)->c_str() )")
  public native static def chdir( path:String ):Int;

  @Native("c++", "system( (#1)->c_str() )")
  public native static def system( cmd:String ):Int;

  public static def mkdir_p( path:String ): Int {
    return system("mkdir -p " + path);
  }

  @Native("c++", "getCWD()")
  public native static def getCWD(): String;

  public def run(): Pair[Long,Rail[Double]] {
    val cwd = getCWD();
    if( cwd.length() == 0n ) {
      Console.ERR.println("[ERROR] failed to cwd");
      throw new Exception("cwd failed");
    }

    var err:Int = 0n;
    val work_dir = workDirPath();
    err = mkdir_p( workDirPath() );
    if( err != 0n ) {
      Console.ERR.println("[ERROR] failed to mkdir " + work_dir );
      throw new Exception("mkdir failed");
    }

    err = chdir(work_dir);
    if( err != 0n ) {
      Console.ERR.println("[ERROR] failed to chdir " + work_dir );
      throw new Exception("chdir failed");
    }

    val rc = system( cmd );

    err = chdir(cwd);
    if( err != 0n ) {
      Console.ERR.println("[ERROR] failed to chdir " + cwd );
      throw new Exception("chdir failed");
    }

    if( rc != 0n ) {
      return Pair[Long,Rail[Double]](rc as Long, new Rail[Double]() );
    }

    val f = new File( resultsFilePath() );
    val results = f.exists() ? parseResults() : (new Rail[Double]() );
    return Pair[Long,Rail[Double]]( 0, results );
  }

  private def parseResults(): Rail[Double] {
    val results = new ArrayList[Double]();
    val f = new File( resultsFilePath() );
    for( line in f.lines() ) {
      val trimmed = line.trim();
      if( trimmed.length() > 0 ) {
        val parsed = trimmed.split(" "); // split by white space
        for( s in parsed ) {
          val d = Double.parse(s);
          results.add(d);
        }
      }
    }
    return results.toRail();
  }

  public def workDirPath(): String {
    return String.format("w%08d", [taskId as Any]);
  }

  public def resultsFilePath(): String {
    return workDirPath() + "/_results.txt";
  }
  
  public def toString(): String {
    return "{ taskId : " + taskId + ", cmd : " + cmd + " }";
  }
}

