/**
  The compiled code ready to be executed
*/
class AST extends Object config(BruteForce);

enum NodeType
{
  NT_Keyword,
  NT_Identifier,
  NT_String,
  NT_Integer,
  NT_Float,
  NT_Boolean,
  NT_Function,
};

struct Node
{
  var NodeType type;
  var string value;
  var int parent;
  var array<int> children;
};
var config array<Node> Tree;

var private int currentNode;

function Create()
{
  Tree.length = 0;
  currentNode = -1;
}

/*
AddRoot
|
+- AddChild
|
+- AddRoot
   |
   +- AddChild
   |
   +- AddChild
   CloseRoot
CloseRoot
*/

/**
  The real add node
*/
private function int AddNode(NodeType inType, string inValue, int inParent)
{
  local int i;
  i = Tree.length;
  Tree.length = i+1;
  Tree[i].type = inType;
  Tree[i].value = inValue;
  Tree[i].parent = inParent;
  if (inParent > -1)
  {
    Tree[inParent].children.length = Tree[inParent].children.length+1;
    Tree[inParent].children[Tree[inParent].children.length-1] = i;
  }
  return i;
}

/**
  Open a new Root to the tree
*/
function AddRoot(NodeType inType, string inValue)
{
  currentNode = AddNode(inType, inValue, currentNode);
}

/**
  Close a Root node 
*/
function CloseRoot()
{
  currentNode = Tree[currentNode].parent;
}

/**
  Add a child to the current node, doesn't set a new root
*/
function AddChild(NodeType inType, string inValue)
{
  AddNode(inType, inValue, currentNode);
}

/**
  Move previous node down a notch
*/
function SwitchNode()
{
  local int lastSib;
  // set new parent
  lastSib = Tree[Tree[currentNode].parent].children[Tree[Tree[currentNode].parent].children.length-2];
  Tree[currentNode].children.length = Tree[currentNode].children.length+1;
  Tree[currentNode].children[Tree[currentNode].children.length-1] = lastSib;
  // remove child pointer from previous parent
  Tree[Tree[lastSib].parent].children.remove(Tree[Tree[lastSib].parent].children.length-2 ,1);
}

/**
  Print the tree
*/
function PrintTree()
{
  local int i;
  for (i = 0; i < Tree.length; i++)
  {
    if (Tree[i].parent == -1) PrintSubTree(i, 0);
  }
}

/**
  Internal function for printing the tree
*/
private function PrintSubTree(int root, int depth)
{
  local int i;
  local string tmp;
  for (i = 0; i < depth; i++) tmp = tmp$"--";
  Log(tmp@Tree[root].value);
  for (i = 0; i < Tree[root].children.length; i++)
  {
    PrintSubTree(Tree[root].children[i], depth+1);
  }
}