/**
  Scanner for the Bruteforce language                   <br />
  Author: Michiel 'El Muerte' Hendriks                  <br />
*/
class BruteForce extends Commandlet config(BruteForce) dependsOn(Tokenizer) dependsOn(Scope);

var private Tokenizer t;
var private Scope s;
var config array<string> Code;

function Parse()
{
  t = new class'Tokenizer';
  s = new class'Scope';
  t.Create(Code);
  t.nextToken();
  _program();
}

function bool has(Tokenizer.tokenType token, optional string text)
{
  if (text == "") return token ~= t.currentToken();
  return (text ~= t.tokenString()) && (token ~= t.currentToken());
}

function _program()
{
  _declarations();
  _statements();
}

function _declarations()
{
  while (has(TT_Identifier, "var")) 
  {
    _declaration();
    assert(has(TT_Literal, ";"));
    t.nextToken();
  }
}

function _declaration()
{
  local string vtype, vname;
  t.nextToken();
  assert(has(TT_Identifier));
  vtype = t.tokenString();
  t.nextToken();
  assert(has(TT_Identifier));
  vname = t.tokenString();
  t.nextToken();  
  s.newDeclaration(vname, s.stringToType(vtype));
}

function _statements()
{
  while (!has(TT_EOF)) 
  {
    _statement();
    assert(has(TT_Literal, ";"));
    t.nextToken();
  }
}

function _statement()
{
  if (has(TT_Identifier, "print"))
  {
    _print();
  }
  else if (has(TT_Identifier, "if"))
  {
    _ifthenelse();
  }
  else if (has(TT_Identifier))
  {
    _assignment();
  }
  else {
    Warn("Unknown operand"@t.tokenString());
    assert(false);
  }
}

function _print()
{
  t.nextToken();
  assert(has(TT_Literal, "("));
  t.nextToken();
  log(_expr(DT_String).value); // print the expression 
  assert(has(TT_Literal, ")"));
  t.nextToken();
}

function _ifthenelse()
{
  local bool isThen;
  t.nextToken();
  isThen = Bool(_expr(DT_Bool).value);  
  assert(has(TT_Identifier, "then"));
  t.nextToken();
  if (isThen) _statement();
  else while (!has(TT_Literal, ";")) t.nextToken();
  t.nextToken();
  assert(has(TT_Identifier, "else"));
  t.nextToken();
  if (!isThen) _statement();
  else while (!has(TT_Literal, ";")) t.nextToken();
}

function _assignment()
{
  local Scope.Declaration result;
  result = s.getDeclaration(t.tokenString());
  t.nextToken();
  assert(has(TT_Literal, "=")); // becomes
  t.nextToken();
  s.setDeclaration(result.name, _expr(result.type).value);
}

function Scope.Declaration _expr(Scope.DeclarationType resultType)
{
  local Scope.Declaration result;
  result = _mult(resultType);
  while (has(TT_Literal, "+") || has(TT_Literal, "-"))
  {
    if (has(TT_Literal, "+"))
    {
      t.nextToken();
      if (resultType == DT_String) result.value = result.value$_mult(resultType).value; 
      else if (resultType == DT_Int) result.value = String(Int(result.value)+Int(_mult(resultType).value)); 
      else if (resultType == DT_Float) result.value = String(Float(result.value)+Float(_mult(resultType).value)); 
      else if (resultType == DT_Bool) result.value = String(Bool(result.value) || Bool(_mult(resultType).value)); 
    }
    else if (has(TT_Literal, "-"))
    {
      t.nextToken();
      if (resultType == DT_String) _mult(resultType); // not supported
      else if (resultType == DT_Int) result.value = String(Int(result.value)-Int(_mult(resultType).value)); 
      else if (resultType == DT_Float) result.value = String(Float(result.value)-Float(_mult(resultType).value)); 
      else if (resultType == DT_Bool) result.value = String(Bool(result.value) && !Bool(_mult(resultType).value)); 
    }
  }
  return result;
}

function Scope.Declaration _mult(Scope.DeclarationType resultType)
{
  local Scope.Declaration result;
  result = _operand(resultType);
  while (has(TT_Literal, "*") || has(TT_Literal, "/"))
  {
    if (has(TT_Literal, "*"))
    {
      t.nextToken();
      if (resultType == DT_String) _operand(resultType); // not supported
      else if (resultType == DT_Int) result.value = String(Int(result.value)*Int(_operand(resultType).value)); 
      else if (resultType == DT_Float) result.value = String(Float(result.value)*Float(_operand(resultType).value)); 
      else if (resultType == DT_Bool) result.value = String(Bool(result.value) && Bool(_operand(resultType).value)); 
    }
    else if (has(TT_Literal, "/"))
    {
      t.nextToken();
      if (resultType == DT_String) _operand(resultType); // not supported
      else if (resultType == DT_Int) result.value = String(Int(result.value)/Int(_operand(resultType).value)); 
      else if (resultType == DT_Float) result.value = String(Float(result.value)/Float(_operand(resultType).value)); 
      else if (resultType == DT_Bool) result.value = String(Bool(result.value) || !Bool(_operand(resultType).value)); 
    }
  }
  return result;
}

function Scope.Declaration _operand(Scope.DeclarationType resultType)
{
  local Scope.Declaration result;

  if (has(TT_Identifier, "true")) 
  {
    result.type = DT_Bool;
    result.value = String(true);
  }
  else if (has(TT_Identifier, "false")) 
  {
    result.type = DT_Bool;
    result.value = String(false);
  }
  else if (has(TT_Identifier)) result = s.getDeclaration(t.tokenString());
  else if (has(TT_String)) 
  {
    result.type = DT_String;
    result.value = t.tokenString();
  }
  else if (has(TT_Integer)) 
  {
    result.type = DT_Int;
    result.value = String(Int(t.tokenString()));
  }
  else if (has(TT_Float)) 
  {
    result.type = DT_Float;
    result.value = String(Float(t.tokenString()));
  }
  else if (has(TT_Literal, "(")) 
  {
    t.nextToken();
    result = _expr(resultType);
    assert(has(TT_Literal, ")"));
    t.nextToken();
  }
  // convert to bool
  if ((resultType == DT_Bool) && (result.type != DT_Bool))
  {    
    if (result.type == DT_String) result.value = String(result.value != "");
    if (result.type == DT_Int) result.value = String(Int(result.value) != 0);
    if (result.type == DT_Float) result.value = String(Float(result.value) != 0.0);
    result.type = DT_Bool;
  }
  t.nextToken();
  return result;
}

/* Main */

event int Main( string Parms )
{
  Parse();  
  return 0;
}
