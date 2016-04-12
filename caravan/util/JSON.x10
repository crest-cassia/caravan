package caravan.util;
import x10.io.File;
import x10.util.ArrayList;
import x10.util.HashMap;
import x10.util.List;
import x10.util.Map;
import x10.util.StringBuilder;

/**
 * A JSON parser with restrictions:
 *
 *     * no type recognition for literals (stored as string)
 *     * no escape sequence handling
 * 
 * Syntax:  json := object
 *          name := ( string | literal )
 *          value := ( object | array | string | literal )
 *          object := "{" [ name ":" value [ "," name ":" value ]* ] "}"
 *          array := "[" [ value [ "," value ]* ] "]"
 *          string := QUOTE [ CHARACTER ]* QUOTE
 *          literal := ( LETTERS | DIGITS | "_" | "." | "+" | "-" )+
 */
public class JSON {

  public static class Value {
    
    var value:Any;
    var p:Stream;
    var i:Int;

    public def this(value:Any, p:Stream, i:Int) {
      this.value = value;
      this.p = p;
      this.i = i;
    }

    public def get[T](s:T):Value {
      if (!this.has(s)) {
        throw new JSONException("No key: " + s);
      }
      if (this.isList()) {
        val i = Long.parse(s.toString());
        return this.asList()(i);
      }
      if (this.isMap()) {
        return this.asMap().get(s.toString());
      }
      throw new JSONException("No key: " + s);
    }

    public def get[T](s:Rail[T]):Value {
      var v:Value = this;
      for (i in 0..(s.size - 1)) {
        if (v.has(s(i))) {
          v = v.get(s(i));
        } else {
          throw new JSONException("No key: " + s);
        }
      }
      return v;
    }

    public def set(v:Any) {
      this.value = v;
    }

    public def put[T](s:T, v:Value) {
      if (this.isList()) {
        val i = Long.parse(s.toString());
        this.asList()(i) = v;
      }
      if (this.isMap()) {
        this.asMap().put(s.toString(), v);
      }
      throw new JSONException("Cannot assign to " + s + ": " + v);
    }

    public def has[T](s:T):Boolean {
      if (this.isList()) {
        val i = Long.parse(s.toString());
        return 0 <= i && i < this.asList().size();
      }
      if (this.isMap()) {
        return this.asMap().containsKey(s.toString());
      }
      return false;
    }

    public def any[T](s:Rail[T]):Value {
      for (i in 0..(s.size - 1)) {
        if (this.has(s(i))) {
          return this.get(s(i));
        }
      }
      throw new JSONException("No key: " + s);
    }

    public def size():Long {
      if (this.isList()) {
        return this.asList().size();
      }
      if (this.isMap()) {
        return this.asMap().size();
      }
      return 0;
    }

    public operator this[T](s:T):Value {
      return this.get(s);
    }

    public operator this[T](s:Rail[T]):Value {
      return this.any(s);
    }

    public def isNull():Boolean {
      return this.value == null;
    }

    public def isMap():Boolean {
      return this.value instanceof Map[String,Value];
    }

    public def asMap():Map[String,Value] {
      return this.value as Map[String,Value];
    }

    public def isList():Boolean {
      return this.value instanceof List[Value];
    }

    public def asList():List[Value] {
      return this.value as List[Value];
    }

    public def toString():String {
      try {
        return this.value as String;
      } catch (Exception) {
        throw new JSONException("Cannot cast to String: " + this.p.toString(this.i));
      }
    }

    public def toBoolean():Boolean {
      try {
        return Boolean.parse(this.value as String);
      } catch (Exception) {
        throw new JSONException("Cannot cast to Boolean: " + this.p.toString(this.i));
      }
    }

    public def toInt():Int {
      try {
        return Int.parse(this.value as String);
      } catch (Exception) {
        throw new JSONException("Cannot cast to Int: " + this.p.toString(this.i));
      }
    }

    public def toLong():Long {
      try {
        return Long.parse(this.value as String);
      } catch (Exception) {
        throw new JSONException("Cannot cast to Long: " + this.p.toString(this.i));
      }
    }

    public def toDouble():Double {
      try {
        return Double.parse(this.value as String);
      } catch (Exception) {
        throw new JSONException("Cannot cast to Double: " + this.p.toString(this.i));
      }
    }
  }

  static class Stream {
    
    public var text:String;
    public var i:Int;

    public def this(text:String) {
      this.text = text;
      this.i = 0n;
    }

    public def get():Char {
      return this.text(this.i);
    }

    public def next() {
      this.i++;
    }

    public def toString(i:Int):String {
      return this.text.substring(Math.max(0n, i - 20n), Math.min(i + 20n, this.text.length()));
    }
  }

  static class JSONException extends Exception {

    public def this(s:String) {
      super(s);
    }
    
    public def this(p:Stream) {
      super(p.toString(p.i));
    }
  }

  public static def isJSONLetter(p:Stream) {
    val c = p.get();
    return (c.isLetter() || c.isDigit() || c == '_' || c == '.' || c == '+' || c == '-');
  }

  public static def isJSONQuote(p:Stream) {
    val c = p.get();
    return (c == '"' || c == '\''); //"
  }

  public static def skipSpaces(p:Stream) {
    while (p.get().isWhitespace()) {
      p.next();
    }
  }

  public static def parseLiteral(p:Stream):String {
    val b = p.i;

    while (isJSONLetter(p)) {
      p.next();
    }
    if (b == p.i) {
      throw new JSONException(p);
    }
    return p.text.substring(b, p.i);
  }

  public static def parseString(p:Stream):String {
    val quote = p.get();
    if (isJSONQuote(p)) {
      p.next();
    } else {
      throw new JSONException(p);
    }

    val b = p.i;

    while (p.i < p.text.length()) {
      if (p.get() == quote) {
        p.next();
        break;
      } else {
        p.next();
      }
    }
    if (p.i >= p.text.length()) {
      throw new JSONException(p);
    }
    return p.text.substring(b, p.i - 1n);
  }

  public static def parseValue(p:Stream):Any {
    if (p.get() == '{') {
      return parseObject(p);
    } else if (p.get() == '[') {
      return parseArray(p);
    } else if (isJSONQuote(p)) {
      return parseString(p);
    } else {
      return parseLiteral(p);
    }
  }

  public static def parseName(p:Stream):String {
    if (isJSONQuote(p)) {
      return parseString(p);
    } else {
      return parseLiteral(p);
    }
  }

  public static def parseObject(p:Stream):Map[String,Value] {
    val a = new HashMap[String,Value]();

    if (p.get() == '{') {
      p.next();
    } else {
      throw new JSONException(p);
    }

    skipSpaces(p);
    if (p.get() == '}') {
      p.next();
      return a;
    }

    while (true) {
      skipSpaces(p);
      val s = parseName(p);

      skipSpaces(p);
      if (p.get() == ':') {
        p.next();
      } else {
        throw new JSONException(p);
      }

      skipSpaces(p);
      val i = p.i;
      val v = parseValue(p);

      a.put(s, new Value(v, p, i));

      skipSpaces(p);
      if (p.get() == ',') {
        p.next();
      } else {
        break;
      }
    }

    skipSpaces(p);
    if (p.get() == '}') {
      p.next();
    } else {
      throw new JSONException(p);
    }
    return a;
  }

  public static def parseArray(p:Stream):List[Value] {
    val a = new ArrayList[Value]();

    if (p.get() == '[') {
      p.next();
    } else {
      throw new JSONException(p);
    }

    skipSpaces(p);
    if (p.get() == ']') {
      p.next();
      return a;
    }

    while (true) {
      skipSpaces(p);
      val i = p.i;
      val v = parseValue(p);

      a.add(new Value(v, p, i));

      skipSpaces(p);
      if (p.get() == ',') {
        p.next();
      } else {
        break;
      }
    }

    skipSpaces(p);
    if (p.get() == ']') {
      p.next();
    } else {
      throw new JSONException(p);
    }
    return a;
  }

  public static def parse(text:String) {
    val p = new Stream(text);
    skipSpaces(p);
    val i = p.i;
    if (p.get() == '{') {
      val map = parseObject(p);
      return new Value(map, p, i);
    }
    else if( p.get() == '[' ) {
      val list = parseArray(p);
      return new Value(list, p, i);
    }
    else {
      throw new JSONException(p);
    }
  }

  public static def parse(file:File) {
    val s = new StringBuilder();
    for (line in file.lines()) {
      s.add(line);
      s.add(" ");
    }
    return parse(s.toString());
  }

  public static def main(args:Rail[String]) {
    var json: JSON.Value = JSON.parse(new File(args(0)));
    parseSampleRunsJson(json);
  }

  private static def parseSample( json: JSON.Value ) {
//    json = JSON.parse("{'first': 1, 'second': 2, 'third': [1,2,'c'], '4th': {'one': { 'more': b.c.c } }, nullobj: { }, 1  : [],  spaces  : 'a a a'    ,   123   : 123  }");

    Console.OUT.println(json.size());
    Console.OUT.println(json("first").size());
    Console.OUT.println(json("first").toDouble());
    Console.OUT.println(json("third").size());
    Console.OUT.println(json("first"));
    Console.OUT.println(json("first").toString());
    
    // json.put("5th", JSON.parse("123"));
    // Console.OUT.println(json("5th"));

    Console.OUT.println("third");
    Console.OUT.println(json("third")(1).toLong());
    Console.OUT.println(json("third")("1").toLong());
    Console.OUT.println(json("third")("1").toDouble());
    Console.OUT.println(json("third")("2").toString());
    Console.OUT.println("end third");
    Console.OUT.println(json("4th")("one")("more").toString());
    Console.OUT.println(json.get(["third", 2]).toString());
    Console.OUT.println(json.get(["third", "2"]).toString());
    Console.OUT.println(json.get(["4th", "one", "more"]).toString());
    // Console.OUT.println(json.get(["4th", "onetwo", "more"]));
    // Console.OUT.println(json("4th")("onetwo")("more"));
    Console.OUT.println(json("4th").any(["three", "two"]).get("more"));
    Console.OUT.println(json("4th")(["three", "two"])("more").toString());
    Console.OUT.println("END");
  }

  private static def parseSampleRunsJson( json: JSON.Value ) {
    p( json.size() );  // => 4
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

  private static def p( o: Any ) {
    Console.OUT.println(o);
  }
}
