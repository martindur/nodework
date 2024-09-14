import gleam/dict.{type Dict}
import gleam/list.{map}
import gleam/pair.{swap}
import gleam/string
import nodework/math.{type Vector, Vector}
import nodework/node.{type Node}

pub type NodeLibrary {
  NodeLibrary(nodes: Dict(String, Node))
}

pub type LibraryMenu {
  LibraryMenu(nodes: List(#(String, String)), position: Vector, visible: Bool)
}

pub fn new() -> NodeLibrary {
  NodeLibrary(dict.new())
}

pub fn register_nodes(nodes: List(Node)) -> NodeLibrary {
  nodes
  |> map(fn(n: Node) { #(n.key, n) })
  |> dict.from_list
  |> fn(nodes) { NodeLibrary(nodes: nodes) }
}

pub fn split_keypair(keypair: String) -> Result(#(String, String), Nil) {
  case string.split(keypair, ".") {
    [category, key] -> Ok(#(category, key))
    _ -> Error(Nil)
  }
}

pub fn generate_lib_menu(lib: NodeLibrary) -> LibraryMenu {
  lib.nodes
  |> dict.map_values(fn(_, node) { node.label })
  |> dict.to_list
  |> map(swap)
  |> fn(nodes) {
    LibraryMenu(nodes: nodes, position: Vector(0, 0), visible: False)
  }
}
