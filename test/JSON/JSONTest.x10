import caravan.util.JSON;

class JSONTest {

  static public def p( obj:Any ): void {
    Console.OUT.println( obj );
  }

  static public def main( args: Rail[String] ) {
    p("> JSONTest");

    p(">>> #testParseObj");
    testParseObj();

    p(">>> #testParseArray");
    testParseArray();

    p(">>> #testParseRunsJson");
    testParseRunsJson();
  }

  static public def testParseObj(): void {
    val str = "{
        'first': 1,
        'second': 2,
        'third': [3,4,'c'],
        'nullobj': { }
      }";
    val json = JSON.parse( str );

    p("first : " + json("first").toLong() );
    p("second : " + json("second").toLong() );
    p("third : " + json("third")(0).toLong() );
    p("nullobj.size : " + json("nullobj").size() );
  }

  static public def testParseArray(): void {
    val str = "[5,4,3,2,1]";
    val json = JSON.parse( str );

    p("0 : " + json(0).toLong() );
    p("4 : " + json(4).toLong() );
    p("size : " + json.size() );
  }

  static public def testParseRunsJson(): void {
    val str = "[
      { \"id\": 0, \"parentPSId\": 0, \"seed\": 787223863, \"result\": { \"duration\": 1574.193008596535492 }, \"placeId\": 1, \"startAt\": 1435112312613, \"finishAt\": 1435112314188 },
      { \"id\": 1, \"parentPSId\": 0, \"seed\": 936703051, \"result\": { \"duration\": 1728.619774797560694 }, \"placeId\": 7, \"startAt\": 1435112312613, \"finishAt\": 1435112314342 },
      { \"id\": 2, \"parentPSId\": 1, \"seed\": 787188363, \"result\": { \"duration\": 1728.619774797560694 }, \"placeId\": 2, \"startAt\": 1435112312613, \"finishAt\": 1435112314342 },
      { \"id\": 3, \"parentPSId\": 1, \"seed\": 306115454, \"result\": { \"duration\": 0.0 }, \"placeId\": 0, \"startAt\": -1, \"finishAt\": -1 }
    ]";

    val json = JSON.parse( str );

    p( json(0)("id") ); // => 0
    p( json(0)("parentPSId") ); // => 0
    p( json(0)("seed") ); // => 787223863
    p( json(0)("result")("duration") ); // => { "duration": 1574.193008596535492 }
    p( json(0)("placeId") ); // => 1
    p( json(0)("startAt") ); // => 1435112312613
    p( json(0)("finishAt") ); // => 1435112314188
    
    p( json(3)("id") ); // => 3
    p( json(3)("parentPSId") ); // => 1
    p( json(3)("seed") ); // => 306115454
    p( json(3)("result")("duration") ); // => { "duration": 0.0 }
    p( json(3)("placeId") ); // => 0
    p( json(3)("startAt") ); // => -1
    p( json(3)("finishAt") ); // => -1
  }
}

