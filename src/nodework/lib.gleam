import gleam/string
import gleam/list.{map}
import nodework/math.{type Vector, Vector}
import nodework/node.{type IntNode, type StringNode}

pub type NodeLibrary {
  NodeLibrary(ints: List(IntNode), strings: List(StringNode))
}

pub type LibraryMenu {
  LibraryMenu(nodes: List(#(String, String)), position: Vector, visible: Bool)
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

fn lib_identifiers(lib: NodeLibrary) -> List(String) {
  let ints = map(lib.ints, fn(n) { n.identifier })
  let strings = map(lib.strings, fn(n) { n.identifier })

  ints
  |> list.append(strings)
}

pub fn generate_lib_menu(lib: NodeLibrary) -> LibraryMenu {
  lib
  |> lib_identifiers
  |> map(fn(identifier) { #(string.capitalise(identifier), string.lowercase(identifier)) })
  |> fn(nodes) {
    LibraryMenu(nodes: nodes, position: Vector(0, 0), visible: False)
  }
}
