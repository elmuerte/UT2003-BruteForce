/**
  Keep track of declarations in diffirent scopes
*/
class Scope extends Object exportstructs;

var private int ScopeLevel;
var int verbose;

enum DeclarationType
{
  DT_None,
  DT_String,
  DT_Int,
  DT_Float,
  DT_Bool,
};

struct Declaration
{
  var string name;
  var string value;
  var int scopelevel;
  var DeclarationType type;
};
var array<Declaration> declarations;

function Declaration getDeclaration(string name, optional DeclarationType type)
{
  local int i;
  for (i = declarations.length-1; i >= 0; i--)
  {
    if ((declarations[i].name ~= name) && (declarations[i].scopelevel <= ScopeLevel))
    {
      if (verbose> 0 ) log(ScopeLevel$"] getDeclaration("$name$", "$type$")", 'Scope');
      return declarations[i];
    }
  }
  Warn("Undeclared identifier:"@name);
  Assert(false);
}

function DeclarationType getType(string name)
{
  local int i;
  for (i = declarations.length-1; i >= 0; i--)
  {
    if ((declarations[i].name ~= name) && (declarations[i].scopelevel <= ScopeLevel))
    {
      if (verbose> 0 ) log(ScopeLevel$"] getType("$name$") ="@declarations[i].type, 'Scope');
      return declarations[i].type;
    }
  }
  Warn("Undeclared identifier:"@name);
  Assert(false);
}

function string setDeclaration(string name, string value, optional DeclarationType type)
{
  local int i;
  for (i = declarations.length-1; i >= 0; i--)
  {
    if ((declarations[i].name ~= name) && (declarations[i].scopelevel <= ScopeLevel))
    {
      if (verbose> 0 ) log(ScopeLevel$"] setDeclaration("$name$", "$value$", "$type$")", 'Scope');
      declarations[i].value = value;
      return declarations[i].value;
    }
  }
  Warn("Undeclared identifier:"@name);
  Assert(false);
}

function newDeclaration(string name, optional DeclarationType type)
{
  local int i;
  for (i = 0; i < declarations.length; i++)
  {
    if ((declarations[i].name ~= name) && (declarations[i].scopelevel == ScopeLevel))
    {
      Warn("Identifier redeclared:"@name);
      Assert(false);
    }
  }
  if (verbose> 0 ) log(ScopeLevel$"] newDeclaration("$name$", "$type$")", 'Scope');
  declarations.length = i+1;
  declarations[i].name = name;
  declarations[i].scopelevel = ScopeLevel;
  declarations[i].type = type;
}

function openScope()
{
  if (verbose> 0 ) log(ScopeLevel$"] openScope()", 'Scope');
  ScopeLevel++;
}

function closeScope()
{
  local int i;
  if (verbose> 0 ) log(ScopeLevel$"] closeScope()", 'Scope');
  for (i = declarations.length-1; i >= 0; i--)
  {
    if (declarations[i].scopelevel >= ScopeLevel)
    {
      declarations.remove(i, 1);
    }
  }
  ScopeLevel--;
}

static function DeclarationType stringToType(string type)
{
  if (type ~= "string") return DT_String;
  else if (type ~= "int") return DT_Int;
  else if (type ~= "float") return DT_Float;
  else if (type ~= "bool") return DT_Bool;
  Warn("Unknown type"@type);
  assert(false);
}

defaultproperties
{
  ScopeLevel=0
  verbose=0
}