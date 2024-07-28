import nodework/node.{type IntNode, type StringNode}

pub type NodeLibrary {
  NodeLibrary(ints: List(IntNode), strings: List(StringNode))
}

pub fn new() -> NodeLibrary {
  NodeLibrary([], [])
}

pub fn register_ints(lib: NodeLibrary, ints: List(IntNode)) -> NodeLibrary {
  NodeLibrary(..lib, ints: ints)
}

pub fn register_strings(
  lib: NodeLibrary,
  strings: List(StringNode),
) -> NodeLibrary {
  NodeLibrary(..lib, strings: strings)
}
