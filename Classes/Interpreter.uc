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
const __AND                   = "&&";
const __OR                    = "||";
const __PLUS                  = "+";
const __MINUS                 = "-";
const __MULTIPLY              = "*";
const __DIVIDE                = "/";
const __MOD                   = "%";
const __NOT                   = "!";
const __TRUE                  = "true";
const __FALSE                 = "false";
// terminals -- end
const FUNCRESULT              = "result";

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
    if (a.Tree[node].value == __FUNC) _function(node);
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

/**
  uscript bool to BruteForce bool
*/
private function string boolToString(bool in)
{
  if (in) return __TRUE;
  else return __FALSE;
}

/**
  Convert from one type to the other
*/
private function Scope.Declaration typeCast(Scope.Declaration d, Scope.DeclarationType type)
{
  if (d.type == type) return d;
  if (type == DT_Int)
  {
    if (d.type == DT_Bool) d.value = String(Int(boolean(d.value)));
    else d.value = String(Int(d.value));
    d.type = DT_Int;
  }
  else if (type == DT_Int)
  {
    if (d.type == DT_Bool) d.value = String(Float(boolean(d.value)));
    else d.value = String(Float(d.value));
    d.type = DT_Float;
  }
  else if (type == DT_Bool)
  {
    if (d.type == DT_String) d.value = boolToString(d.value != "");
    else if (d.type == DT_Int) d.value = boolToString(Int(d.value) != 0);
    else if (d.type == DT_Float) d.value = boolToString(Float(d.value) != 0.0);
    else d.value = boolToString(Boolean(d.value));
    d.type = DT_Bool;
  }
  else if (type == DT_String)
  {
    d.type = DT_String;
  }
  return d;
}

private function _var(int node, optional string initval)
{
                   // name                                 value
  s.newDeclaration(ChildValue(node, 1), s.stringToType(ChildValue(node, 0)), initval);
}

private function _assignment(int node)
{                  // name              expression            left hand type
  s.setDeclaration(ChildValue(node, 0), typeCast(_expr(Child(node, 1)), s.getType(ChildValue(node, 0))).value );
}

private function _ifthenelse(int node)
{
  if (boolean(typeCast(_expr(Child(node, 0)), DT_Bool).value)) //if true
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
  while (boolean(typeCast(_expr(Child(node, 0)), DT_Bool).value)) //while true
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
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) < Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) < Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Int(Boolean(d.value)) < Int(Boolean(_expr(Child(node, 1), type).value)));
      if (type == DT_String) d.value = boolToString(d.value < _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __LE)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) <= Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) <= Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Int(Boolean(d.value)) <= Int(Boolean(_expr(Child(node, 1), type).value)));
      if (type == DT_String) d.value = boolToString(d.value <= _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __GT)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) > Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) > Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Int(Boolean(d.value)) > Int(Boolean(_expr(Child(node, 1), type).value)));
      if (type == DT_String) d.value = boolToString(d.value > _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __GE)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) >= Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) >= Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Int(Boolean(d.value)) >= Int(Boolean(_expr(Child(node, 1), type).value)));
      if (type == DT_String) d.value = boolToString(d.value >= _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __EQ)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) == Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) == Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Boolean(d.value) == Boolean(_expr(Child(node, 1), type).value));
      if (type == DT_String) d.value = boolToString(d.value == _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __NE)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = boolToString(Int(d.value) != Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = boolToString(Float(d.value) != Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = boolToString(Boolean(d.value) != Boolean(_expr(Child(node, 1), type).value));
      if (type == DT_String) d.value = boolToString(d.value != _expr(Child(node, 1), type).value);
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __AND)
    {
      d = _expr(Child(node, 0));
      d.value = boolToString( Boolean(d.value) && Boolean(_expr(Child(node, 1)).value) );
      d.type = DT_Bool;
      return d;
    }
    else if (a.Tree[node].value == __OR)
    {
      d = _expr(Child(node, 0));
      d.value = boolToString(Boolean(d.value) || Boolean(_expr(Child(node, 1)).value));
      d.type = DT_Bool;
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
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) + Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = String(Float(d.value) + Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = String(Boolean(d.value) && !Boolean(_expr(Child(node, 1), type).value));
      if (type == DT_String) d.value = d.value $ _expr(Child(node, 1), type).value;
      return d;
    }
    else if (a.Tree[node].value == __MINUS)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) - Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = String(Float(d.value) - Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = String(Boolean(d.value) && !Boolean(_expr(Child(node, 1), type).value));
      if (type == DT_String) _expr(Child(node, 1), type).value;
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
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value = String(Int(d.value) * Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = String(Float(d.value) * Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = String(Boolean(d.value) || Boolean(_expr(Child(node, 1), type).value)); 
      if (type == DT_String) _expr(Child(node, 1), type); // ??
      return d;
    }
    else if (a.Tree[node].value == __DIVIDE)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value =  String(Int(d.value) / Int(_expr(Child(node, 1), type).value));
      if (type == DT_Float) d.value = String(Float(d.value) / Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) d.value = String(Boolean(d.value) || !Boolean(_expr(Child(node, 1), type).value)); 
      if (type == DT_String) _expr(Child(node, 1), type); //?
      return d;
    }
    else if (a.Tree[node].value == __MOD)
    {
      d = _expr(Child(node, 0), type);
      type = d.type;
      if (type == DT_Int) d.value =  String(Int(Int(d.value) % Int(_expr(Child(node, 1), type).value)));
      if (type == DT_Float) d.value = String(Float(d.value) % Float(_expr(Child(node, 1), type).value));
      if (type == DT_Bool) _expr(Child(node, 1), type); // ??
      if (type == DT_String) _expr(Child(node, 1), type); //?
      return d;
    }
  }
  return _preop(node, type);
}

private function Scope.Declaration _preop(int node, optional Scope.DeclarationType type)
{
  local Scope.Declaration d;
  if (a.Tree[node].type == NT_Keyword)
  {
    if (a.Tree[node].value == __NOT)
    {
      d.type = DT_Bool;
      d.value = BoolToString(!Boolean(_expr(Child(node, 0), DT_Bool).value));
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
  if ((type != DT_None) && (d.type != type)) d = typeCast(d, type); // from to
  return d;
}

private function Scope.Declaration _functioncall(int node)
{
  local Scope.Declaration d;
  if (a.Tree[node].value ~= "print")
  {
    d = typeCast(_expr(Child(node, 0)), DT_String);
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
  if (a.Tree[node].value ~= "int")
  {
    d = typeCast(_expr(Child(node, 0)), DT_Int);
    return d;
  }
  if (a.Tree[node].value ~= "float")
  {
    d = typeCast(_expr(Child(node, 0)), DT_Float);
    return d;
  }
  if (a.Tree[node].value ~= "string")
  {
    d = typeCast(_expr(Child(node, 0)), DT_String);
    return d;
  }
  if (a.Tree[node].value ~= "bool")
  {
    d = typeCast(_expr(Child(node, 0)), DT_Bool);
    return d;
  }
  else {
    d = s.getDeclaration(a.Tree[node].value, DT_Function);
    d = _execfunction(int(d.value), node);
    return d;
  }
  Warn("Undeclared function:"@a.Tree[node].value);
  Assert(false);
}

private function _function(int node)
{
  //               function name        
  s.newDeclaration(ChildValue(node, 1), DT_Function, string(node));
}

private function Scope.Declaration _execfunction(int func, int node)
{
  local Scope.Declaration d;
  local int i, j;
  s.openScope();                      
  s.newDeclaration(FUNCRESULT, s.stringToType(ChildValue(func, 0))); // return type
  j = Child(func, 1);
  for (i = 0; i < a.tree[j].children.length; i++)
  {
    _var(Child(j, i), _expr(Child(node, i)).value);
  }
  for (i = 2; i < a.tree[func].children.length; i++) // 0 = return type, 1 = function name
  {
    ExecuteRoot(a.Tree[func].children[i]);
  }
  d = s.getDeclaration(FUNCRESULT);
  s.closeScope();
  return d;
}

