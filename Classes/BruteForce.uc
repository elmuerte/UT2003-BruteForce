/**
  Scanner for the Bruteforce language                   <br />
  Author: Michiel 'El Muerte' Hendriks                  <br />
*/
class BruteForce extends Commandlet config(BruteForce);

var private Tokenizer t;
var private Scope s;
var private Compiler c;
var private AST a;
var private Interpreter i;
var config array<string> Code;
var array<string> Input;

/* Main */

event int Main( string Parms )
{
  class'wString'.static.split2(Parms, " ", Input, true, "\"");
  
  t = new class'Tokenizer';
  s = new class'Scope';
  c = new class'Compiler';
  a = new class'AST';
  i = new class'Interpreter';

  t.Create(Code);
  a.Create();

  StopWatch(false);
  t.nextToken();
  c.Compile(t, a);
  Log("Compile time: ");
  StopWatch(true);

  //a.printTree();

  StopWatch(false);
  i.Create(a, s, input);
  i.Execute();
  Log("Execution time: ");
  StopWatch(true);

  return 0;
}
