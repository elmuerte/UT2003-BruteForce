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
  local int n;
  local bool showTree, saveTree, noCompile;
  showTree = false;
  saveTree = false;
  noCompile = false;
  class'wString'.static.split2(Parms, " ", Input, true, "\"");
  for (n = input.length-1; n >= 0; n--)
  {
    if (input[n] ~= "-showtree")
    {
      input.remove(n, 1);
      showTree = true;
    }
    else if (input[n] ~= "-savetree")
    {
      input.remove(n, 1);
      saveTree = true;
    }
    else if (input[n] ~= "-nocompile")
    {
      input.remove(n, 1);
      noCompile = true;
    }
  }
    
  s = new class'Scope';  
  a = new class'AST';
  i = new class'Interpreter';
   
  if (!noCompile)
  {
    t = new class'Tokenizer';
    c = new class'Compiler';
    t.Create(Code);
    a.Create();
    StopWatch(false);
    t.nextToken();
    c.Compile(t, a);
    Log("Compile time: ");
    StopWatch(true);
  }

  if (showTree) a.printTree();

  StopWatch(false);
  i.Create(a, s, input);
  i.Execute();
  Log("Execution time: ");
  StopWatch(true);

  if (saveTree) a.SaveConfig();

  return 0;
}
