/**
  Analyse and compile the language (create an AST)
*/
class Compiler extends Object dependsOn(Tokenizer) dependsOn(Scope);

// terminals
const __BEGIN                 = "begin";
const __END                   = "end";
const __SEMICOLON             = ";";
const __VAR                   = "var";
const __INTEGER               = "int";
const __STRING                = "string";
const __FLOAT                 = "float";
const __BOOLEAN               = "bool";
const __UNDERSCORE            = "_";
const __BECOMES               = "=";
const __WHILE                 = "while";
const __DO                    = "do";
const __IF                    = "if";
const __THEN                  = "then";
const __ELSE                  = "else";
const __LT                    = "<";
const __LE                    = "<=";
const __GT                    = ">";
const __GE                    = ">=";
const __EQ                    = "==";
const __NE                    = "!=";
const __PLUS                  = "+";
const __MINUS                 = "-";
const __MULTIPLY              = "*";
const __DIVIDE                = "/";
const __LBRACK                = "(";
const __RBRACK                = ")";
const __TRUE                  = "true";
const __FALSE                 = "false";
// terminals -- end

var private Tokenizer t;

function bool has(Tokenizer.tokenType token, optional string text)
{
  if (text == "") return token ~= t.currentToken();
  return (text ~= t.tokenString()) && (token ~= t.currentToken());
}

function require(Tokenizer.tokenType token, optional string text)
{
  assert(has(token, text));
}

function _program()
{
  require(TT_Identifier, __BEGIN);
  t.nextToken();
  _declarations();
  _statements();
  require(TT_Identifier, __END);
  t.nextToken();
}

function _declarations()
{
  while (has(TT_Identifier, __VAR))
  {
    _declaration();
    require(TT_Literal, __SEMICOLON);
    t.nextToken();
  }
}

function _declaration()
{
  local Scope.DeclarationType dtype;
  local string did;
  t.nextToken(); // __VAR
  dtype = _type();
  require(TT_Identifier);
  did = t.tokenString();
  t.nextToken();
  // FIXME: add AST node
}

function Scope.DeclarationType _type()
{
  if (has(TT_Identifier, __INTEGER)) 
  {
    t.nextToken();
    return DT_Int;
  }
  else if (has(TT_Identifier, __STRING)) 
  {
    t.nextToken();
    return DT_String;
  }
  else if (has(TT_Identifier, __FLOAT)) 
  {
    t.nextToken();
    return DT_Float;
  }
  else if (has(TT_Identifier, __BOOLEAN)) 
  {
    t.nextToken();
    return DT_Bool;
  }
  else {
    Warn("Unrecognised type:"@t.tokenString());
    assert(false);
  }
}

function _statements()
{
  while (!has(TT_Identifier, __END))
  {
    _statement();
    require(TT_Literal, __SEMICOLON);
    t.nextToken();
  }
}

function _statement()
{
  if (has(TT_Identifier, __WHILE)) _whiledo();
  else if (has(TT_Identifier, __IF)) _ifthenelse();
  else if (has(TT_Identifier)) _assignment();
  else {
    Warn("Unrecognised statement:"@t.tokenString());
    assert(false);
  }
}

function _whiledo()
{
  t.nextToken(); // WHILE
  _expr();
  require(TT_Identifier, __DO);
  t.nextToken();
  _codeblock();
}

function _codeblock()
{
  if (has(TT_Identifier, __BEGIN))
  {
    t.nextToken();
    _statements();
    require(TT_Identifier, __END);
    t.nextToken();
  }
  else {
    _statement();
  }
}

function _ifthenelse()
{
  t.nextToken(); // IF
  _expr();
  require(TT_Identifier, __THEN);
  t.nextToken();
  _codeblock();
  if (has(TT_Identifier, __ELSE))
  {
    t.nextToken();
    _codeblock();
  }
}

function _assignment()
{
  _lvalue();
  require(TT_Operator, __BECOMES);
  t.nextToken();
  _expr();
}

function _lvalue()
{
  require(TT_Identifier);
  t.nextToken();
}

function _expr()
{
  _boolex();
}

function _boolex()
{
  _accum();
  while (has(TT_Operator, __LT)||has(TT_Operator, __LE)||has(TT_Operator, __GT)||has(TT_Operator, __GE)||
    has(TT_Operator, __EQ)||has(TT_Operator, __NE))
  {
    t.nextToken();
    _accum();
  }
}

function _accum()
{
  _mult();
  while (has(TT_Operator, __PLUS)||has(TT_Operator, __MINUS))
  {
    t.nextToken();
    _mult();
  }
}

function _mult()
{
  _operand();
  while (has(TT_Operator, __MULTIPLY)||has(TT_Operator, __DIVIDE))
  {
    t.nextToken();
    _operand();
  }
}

function _operand()
{
  if (has(TT_Identifier, __TRUE))
  {
  }
  else if (has(TT_Identifier, __FALSE))
  {
  }
  else if (has(TT_Identifier))
  {
    // identifier
  }
  else if (has(TT_Integer))
  {
  }
  else if (has(TT_String))
  {
  }
  else if (has(TT_Float))
  {
  }
  else if (has(TT_Literal, "("))
  {
    t.nextToken();
    _expr();
    require(TT_Literal, ")");
    t.nextToken();
  }
  else {
    Warn("Unexpected token:"@t.tokenString());
    assert(false);
  }
}