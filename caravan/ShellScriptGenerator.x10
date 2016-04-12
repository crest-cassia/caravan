package caravan;

import x10.io.Console;
import x10.io.File;

class ShellScriptGenerator {

  public static def generateScript( run_id:Long, cmd:String ):String {

    val script = 
      "#!/bin/bash\n" +
      "LC_ALL=C\n" +
      "\n" +
      "# PREPROCESS ---\n" +
      "mkdir -p " + run_id + " && cd " + run_id + "\n" +
      "echo \"{\" > ../" + run_id + "_status.json\n" +
      "echo \"  \\\"started_at\\\": \\\"`date`\\\",\" >> ../" + run_id + "_status.json\n" +
      "echo \"  \\\"hostname\\\": \\\"`hostname`\\\",\" >> ../" + run_id + "_status.json\n" +
      "\n" +
      "# JOB EXECUTION ---\n" +
      "{ time -p { { " + cmd + "; } 1>> _stdout.txt 2>> _stderr.txt; } } 2>> ../" + run_id + "_time.txt\n" +
      "echo \"  \\\"rc\\\": $?,\" >> ../" + run_id + "_status.json\n" +
      "echo \"  \\\"finished_at\\\": \\\"`date`\\\"\" >> ../" + run_id + "_status.json\n" +
      "echo \"}\" >> ../" + run_id + "_status.json\n" +
      // "cd .. && tar cvf " + run_id + ".tar " + run_id  + "\n" +
      // "bzip2 " + run_id + ".tar\n";
      "";

    val scriptPath = run_id + ".sh";
    val out = new File( scriptPath );
    val printer = out.printer();
    printer.println(script);
    printer.flush();

    return scriptPath;
  }

  static public def main( args:Rail[String] ): void {
    val s = generateScript(12345, "echo hello");
    Console.OUT.println("script path: " + s);
  }
}

