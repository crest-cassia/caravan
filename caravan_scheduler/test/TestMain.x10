package test;


import test.DequeTest;
import test.TaskTest;
import test.OptionParserTest;

class TestMain {
  
  static public def main( args: Rail[String] ) {
    Console.ERR.println("> Starting All Tests");

    DequeTest.main(args);
    TaskTest.main(args);
    OptionParserTest.main(args);

    Console.ERR.println("> Finished All Tests");
  }
}

