/**
  Tokenizer returns tokens from a buffer                <br />
  Author: Michiel 'El Muerte' Hendriks                  <br />
  TODO:
  - fix string, unescape \"
*/
class Tokenizer extends Object;

const NEWLINE = 10;

var private array<string> buffer;
var private byte c; // holds current char
var private int linenr;
var private int pos;

var int verbose;

enum tokenType 
{
  TT_None,
  TT_Literal,
  TT_Identifier,  
  TT_Integer,
  TT_Float,
  TT_String,
  TT_EOF,
};
var private tokenType curTokenType;
var private string curTokenString;

/**
  Create a tokenizer
*/
function Create(array<string> buf)
{
  buffer.length = 0;
  buffer = buf;
  linenr = 0;
  pos = 0;
  c = 0;
}

/**
  returns the string representation of the current token
*/
function string tokenString()
{
  return curTokenString;
}

/**
  returns the type of the current token
*/
function tokenType currentToken()
{
  return curTokenType;
}

/**
  retreives the next token
*/
function tokenType nextToken()
{
  return _nextToken();
}

/* Private functions */

private function tokenType _nextToken()
{
  local int tokenPos, endPos;
  skipBlanks();
  if (curTokenType == TT_EOF) return curTokenType; 
  tokenPos = pos;
  // identifier: [A-Za-z]([A-Za-z0-9_])*
  if (((c >= 65) && (c <= 90)) || ((c >= 97) && (c <= 122)) || (c == 95))
  {
    pos++;
    c = _c();
    while (((c >= 65) && (c <= 90)) || ((c >= 97) && (c <= 122)) || (c == 95) || ((c >= 48) && (c <= 57)))
    {
      pos++;
      c = _c();
    }
    endPos = pos;
    curTokenType = TT_Identifier;
  }
  // number: (-)?[0-9]+(\.([0-9])+)?
  else if (((c >= 48) && (c <= 57)) || (c == 45)) // -
  {
    pos++;
    c = _c();
    while ((c >= 48) && (c <= 57))
    {
      pos++;
      c = _c();
    }
    if (c == 46) // .
    {
      pos++;
      c = _c();
      while ((c >= 48) && (c <= 57))
      {
        pos++;
        c = _c();
      }
      endPos = pos;
      curTokenType = TT_Float;
    }
    else {
      endPos = pos;
      curTokenType = TT_Integer;
    }
  }
  // string: "[^"]*"
  else if (c == 34)
  {
    pos++;
    c = _c();
    while (true)
    {
      if (c == 34) break;
      if (c == 92) // escape char skip one char
      {
        pos++;
      }
      if (c == NEWLINE)
      {
        Warn("Unterminated string @"@linenr$","$pos);
        assert(false);
      }
      pos++;
      c = _c();
    }
    tokenPos++;
    endPos = pos;
    pos++;
    curTokenType = TT_String;
  }
  // literal
  else {
    pos++;
    endPos = pos;
    curTokenType = TT_Literal;
  }
  // make up result
  if (linenr >= buffer.length) // EOF break
  {
    curTokenType = TT_EOF; 
    curTokenString = "";
  }
  else {
    curTokenString = Mid(buffer[linenr], tokenPos, endPos-tokenPos);
  }
  if (verbose > 0) log(curTokenType@curTokenString, 'Tokenizer');
  return curTokenType;
}

/**
  Skip all characters with ascii value < 33 (32 is space)
*/
private function skipBlanks()
{  
  c = _c();
  while (c < 33)
  {
    if (c == NEWLINE)
    {
      linenr++;
      pos = 0;
      if (linenr >= buffer.length) // EOF break
      {
        curTokenType = TT_EOF; 
        curTokenString = "";
        return;
      }
    }
    else pos++;
    c = _c();
  }
}

/**
  returns the current char
*/
private function byte _c(optional int displacement)
{
  local string t;
  t =  Mid(buffer[linenr], pos+displacement, 1);
  if (t == "") return NEWLINE; // empty string is a newline
  return Asc(t);
}

defaultproperties
{
  verbose=0
}