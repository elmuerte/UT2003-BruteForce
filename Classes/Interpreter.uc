class Interpreter extends Object dependsOn(AST) dependsOn(Scope) dependsOn(Compiler);

var private AST a;
var private Scope s;
var private array<string> input;

// keywords
const __BEGIN                 = "begin";
const __VAR                   = "var";
const __INTEGER               = "int";
const __STRING                = "string";
const __FLOAT                 = "float";
const __BOOLEAN               = "bool";
const __FUNC                  = "function";
const __BECOMES               = "=";
const __WHILE                 = "while";
const __IF                    = "if";
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
const __TRUE                  = "true";
const __FALSE                 = "false";
// terminals -- end

function Create(AST inAst, Scope inScope, array<string> inInput)
{
  a = inAst;
  s = inScope;
  input = inInput;
}

function Execute()
{
  local int i;
  for (i = 0; i < a.Tree.length; i++)
  {
    if (a.Tree[i].parent == -1) ExecuteRoot(i);
  }
}

private function ExecuteRoot(int node)
{
  local Scope.Declaration d;
  if (a.Tree[node].type == NT_Keyword)
  {
    if (a.Tree[node].value == __VAR) _var(node);
    if (a.Tree[node].value == __BECOMES) _assignment(node);
    if (a.Tree[node].value == __IF) _ifthenelse(node);
    if (a.Tree[node].value == __WHILE) _whiledo(node);
  }
  if (a.Tree[node].type == NT_Function)
  {
    d = _functioncall(node);
  }
}

/**
  returns the value of the nth child
*/
private function string ChildValue(int node, optional int n)
{
  return a.Tree[a.Tree[node].children[n]].value;
}

/**
  returns the id of the nth child
*/
private function int Child(int node, optional int n)
{
  return a.Tree[node].children[n];
}

/**
  converts BruteForce bool to UScript bool
*/
private function bool boolean(string in)
{
  return !(in ~= __FALSE);
}

private function string boolToString(bool in)
{
  if (in) return __TRUE;
  else return __FALSE;
}

private function _var(int node)
{
                   // name                                 value
  s.newDeclaration(ChildValue(node, 1), s.stringToType(ChildValue(node, 0)));
}

private function _assignment(int node)
{                  // name              expression            left hand type
  s.setDeclaration(ChildValue(node, 0), _expr(Child(node, 1), s.getType(ChildValue(node, 0))).value);
}

private function _ifthenelse(int node)
{
  if (boolean(_expr(Child(node, 0)).value)) //if true
  {
    _codeblock(Child(node, 1)); // then
  }
  else if (a.Tree[node].children.length >= 3) // else
  {
    _codeblock(Child(node, 2));
  }
}

private function _whiledo(int node)
{
  while (boolean(_expr(Child(node, 0)).value)) //while true
  {
    _codeblock(Child(node, 1)); // do
  }  
}

private function _codeblock(int node)
{
  local int i;
  if ((a.Tree[node].type == NT_Keyword) && (a.Tree[node].value == __BEGIN))
  {
    for (i = 0; i < a.Tree[node].children.length; i++)
    {
      ExecuteRoot(a.Tree[node].children[i]);
    }
  }
  else {
    ExecuteRoot(node);
  }
}

private function Scope.Declaration _expr(int node, optional Scope.DeclarationType type)
{
  return _boolex(node, type);
}

private function Scope.Declaration _boolex(int node, optional Scope.DeclarationType type)
{
  local Scope.Declaration d;
  if (a.Tree[node].type == NT_Keyword)
  {
    if (a.Tree[node].value == __LT)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) < Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __LE)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) <= Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __GT)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) > Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __GE)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) >= Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __EQ)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) == Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __NE)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) != Int(_expr(Child(node, 1), type).value));
      return d;
    }
  }
  return _accum(node, type);
}

private function Scope.Declaration _accum(int node, optional Scope.DeclarationType type)
{
  local Scope.Declaration d;
  if (a.Tree[node].type == NT_Keyword)
  {
    if (a.Tree[node].value == __PLUS)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) + Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __MINUS)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) - Int(_expr(Child(node, 1), type).value));
      return d;
    }
  }
  return _mult(node, type);
}

private function Scope.Declaration _mult(int node, optional Scope.DeclarationType type)
{
  local Scope.Declaration d;
  if (a.Tree[node].type == NT_Keyword)
  {
    if (a.Tree[node].value == __MULTIPLY)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) * Int(_expr(Child(node, 1), type).value));
      return d;
    }
    else if (a.Tree[node].value == __DIVIDE)
    {
      d = _expr(Child(node, 0));
      type = d.type;
      if (type == DT_Int) d.value =  String(Int(d.value) / Int(_expr(Child(node, 1), type).value));
      return d;
    }
  }
  return _operand(node, type);
}

private function Scope.Declaration _operand(int node, optional Scope.DeclarationType type)
{
  local Scope.Declaration d;
  d.value = a.Tree[node].value;
  if (a.Tree[node].type == NT_Identifier)
  {
    d = s.getDeclaration(a.Tree[node].value);
  }
  else if (a.Tree[node].type == NT_String)
  {
    d.type = DT_String;
  }
  else if (a.Tree[node].type == NT_Boolean)
  {
    d.type = DT_Bool;
  }
  else if (a.Tree[node].type == NT_Integer)
  {
    d.type = DT_Int;
  }
  else if (a.Tree[node].type == NT_Float)
  {
    d.type = DT_Float;
  }
  else if (a.Tree[node].type == NT_Function)
  {
    d = _functioncall(node);
  }
  else {
    Warn("Unexpected node:"@a.Tree[node].value);
    Assert(false);
  }
  //if (d.type != type) d = typeCast(d.type, type); // from to
  return d;
}

private function Scope.Declaration _functioncall(int node)
{
  local Scope.Declaration d;
  if (a.Tree[node].value ~= "print")
  {
    d = _expr(Child(node, 0));
    log(d.value);
    return d;
  }
  if (a.Tree[node].value ~= "argc")
  {
    d.type = DT_Int;
    d.value = String(input.length);
    return d;
  }
  if (a.Tree[node].value ~= "argv")
  {
    d.type = DT_String;
    d.value = input[Int(_expr(Child(node, 0), DT_Int).value)];
    return d;
  }
  else {
    Warn("Undeclared function:"@a.Tree[node].value);
    Assert(false);
  }
}