/**
  Analyse and compile the language (create an AST)
*/
class Compiler extends Object dependsOn(Tokenizer) dependsOn(AST);

// terminals
const __BEGIN                 = "begin";
const __END                   = "end";
const __SEMICOLON             = ";";
const __VAR                   = "var";
const __INTEGER               = "int";
const __STRING                = "string";
const __FLOAT                 = "float";
const __BOOLEAN               = "bool";
const __FUNC                  = "function";
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
const __NOT                   = "!";
const __LBRACK                = "(";
const __RBRACK                = ")";
const __TRUE                  = "true";
const __FALSE                 = "false";
const __COMMA                 = ",";
// terminals -- end

var private Tokenizer t;
var private AST a;

function Compile(Tokenizer tokenizer, AST tree)
{
  t = tokenizer;
  a = tree;
  _program();
}

function bool has(Tokenizer.tokenType token, optional string text)
{
  if (text == "") return token ~= t.currentToken();
  return (text ~= t.tokenString()) && (token ~= t.currentToken());
}

function require(Tokenizer.tokenType token, optional string text)
{
  local bool res;
  res = has(token, text);
  if (!res)
  {
    Warn("Expected ("$token$") \""$text$"\" but has ("$t.currentToken()$") \""$t.tokenString()$"\" @ "$t.currentLine()$","$t.currentPos());
    assert(false);
  }
}

function _program()
{
  _declarations();
  _statements();
  require(TT_EOF);
}

function _declarations()
{
  while (has(TT_Identifier, __VAR) || has(TT_Identifier, __FUNC))
  {
    if (has(TT_Identifier, __VAR)) _declaration();
    else if (has(TT_Identifier, __FUNC)) _function();
    require(TT_Literal, __SEMICOLON);
    t.nextToken();
  }
}

function _declaration()
{
  a.AddRoot(NT_Keyword, __VAR);
  t.nextToken(); // __VAR
  _type();
  require(TT_Identifier);
  a.AddChild(NT_Identifier, t.tokenString());
  t.nextToken();
  a.CloseRoot();
}

function _type()
{
  if (has(TT_Identifier, __INTEGER)) 
  {
    a.AddChild(NT_Keyword, __INTEGER);
    t.nextToken();
  }
  else if (has(TT_Identifier, __STRING)) 
  {
    a.AddChild(NT_Keyword, __STRING);
    t.nextToken();
  }
  else if (has(TT_Identifier, __FLOAT)) 
  {
    a.AddChild(NT_Keyword, __FLOAT);
    t.nextToken();
  }
  else if (has(TT_Identifier, __BOOLEAN)) 
  {
    a.AddChild(NT_Keyword, __BOOLEAN);
    t.nextToken();
  }
  else {
    Warn("Unrecognised type:"@t.tokenString()@"@ "$t.currentLine()$","$t.currentPos());
    assert(false);
  }
}

function _function()
{
  t.nextToken(); // function
  _type();
  require(TT_Identifier);
  t.tokenString();
  t.nextToken();
  require(TT_Literal, __LBRACK);
  t.nextToken();
  _arguments();
  require(TT_Literal, __RBRACK);
  t.nextToken();
  _declarations();
  require(TT_Identifier, __BEGIN);
  t.nextToken();
  _statements();
  require(TT_Identifier, __END);
  t.nextToken();
}

function _arguments()
{
  while (!has(TT_Literal, __RBRACK))
  {
    _type();
    require(TT_Identifier);
    // did
    t.nextToken();
    require(TT_Literal, __SEMICOLON);
    t.nextToken();
  }
}

function _statements()
{
  while (!(has(TT_Identifier, __END) || has(TT_EOF)))
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
    Warn("Unrecognised statement:"@t.tokenString()@"@ "$t.currentLine()$","$t.currentPos());
    assert(false);
  }
}

function _whiledo()
{
  a.AddRoot(NT_Keyword, __WHILE);
  t.nextToken(); // WHILE
  _expr();
  require(TT_Identifier, __DO);
  t.nextToken();
  _codeblock();
  a.CloseRoot();
}

function _codeblock()
{
  if (has(TT_Identifier, __BEGIN))
  {
    a.AddRoot(NT_Keyword, __BEGIN);
    t.nextToken();
    _statements();
    require(TT_Identifier, __END);
    t.nextToken();
    a.CloseRoot();
  }
  else {
    _statement();
  }
}

function _ifthenelse()
{
  a.AddRoot(NT_Keyword, __IF);
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
  a.CloseRoot();
}

function _assignment()
{
  local string tmp;
  tmp = t.tokenString();
  t.nextToken();
  if (has(TT_Literal, __LBRACK)) _functioncall(tmp);
  else {
    a.AddRoot(NT_Keyword, __BECOMES);
    a.AddChild(NT_Identifier, tmp);
    require(TT_Operator, __BECOMES);
    t.nextToken();
    _expr();
    a.CloseRoot();
  }
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
    a.AddRoot(NT_Keyword, t.tokenString());
    a.SwitchNode();
    t.nextToken();
    _accum();
    a.CloseRoot();
  }
}

function _accum()
{
  _mult();
  while (has(TT_Operator, __PLUS)||has(TT_Operator, __MINUS))
  {
    a.AddRoot(NT_Keyword, t.tokenString());
    a.SwitchNode();
    t.nextToken();
    _mult();
    a.CloseRoot();
  }
}

function _mult()
{
  _preop();
  while (has(TT_Operator, __MULTIPLY)||has(TT_Operator, __DIVIDE))
  {
    a.AddRoot(NT_Keyword, t.tokenString());
    a.SwitchNode();
    t.nextToken();
    _preop();
    a.CloseRoot();
  }
}

function _preop()
{
  local bool open;
  open = false;
  if (has(TT_Operator, __MINUS))
  {
    open = true;
    a.AddRoot(NT_Keyword, __MINUS);
    a.AddChild(NT_Integer, "0");
    t.nextToken();
  }
  else if (has(TT_Operator, __NOT))
  {
    open = true;
    a.AddRoot(NT_Keyword, __NOT);
    t.nextToken();
  }
  _operand();
  if (open) a.CloseRoot();
}

function _operand()
{
  local string tmp;
  if (has(TT_Identifier, __TRUE))
  {
    a.AddChild(NT_Boolean, t.tokenString());
    t.nextToken();
  }
  else if (has(TT_Identifier, __FALSE))
  {
    a.AddChild(NT_Boolean, t.tokenString());
    t.nextToken();
  }
  else if (has(TT_Identifier))
  {    
    tmp = t.tokenString();
    t.nextToken();
    if (has(TT_Literal, __LBRACK)) // is function ??
    {
      _functioncall(tmp);
    }
    else {
      a.AddChild(NT_Identifier, tmp);
    }
  }
  else if (has(TT_Integer))
  {
    a.AddChild(NT_Integer, t.tokenString());
    t.nextToken();
  }
  else if (has(TT_String))
  {
    a.AddChild(NT_String, t.tokenString());
    t.nextToken();
  }
  else if (has(TT_Float))
  {
    a.AddChild(NT_Float, t.tokenString());
    t.nextToken();
  }
  else if (has(TT_Literal, __LBRACK))
  {
    t.nextToken();
    _expr();
    require(TT_Literal, __RBRACK);
    t.nextToken();
  }
  else {
    Warn("Unexpected token:"@t.tokenString()@"@ "$t.currentLine()$","$t.currentPos());
    assert(false);
  }
}

function _functioncall(string name)
{
  a.AddRoot(NT_Function, name);
  t.nextToken();
  while (!has(TT_Literal, __RBRACK))
  {
    _expr();
    if (has(TT_Literal, __COMMA)) t.nextToken();
    else break;
  }
  require(TT_Literal, __RBRACK);
  t.nextToken(); // __RBRACK
  a.CloseRoot();
}
