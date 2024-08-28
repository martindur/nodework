import gleam/io
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/string
import gleam/list.{map}
import gleam/pair.{swap}
import nodework/math.{type Vector, Vector}
import nodework/node.{type IntNode, type StringNode}

pub type NodeLibrary {
  NodeLibrary(ints: Dict(String, IntNode), strings: Dict(String, StringNode))
}

pub type LibraryMenu {
  LibraryMenu(nodes: List(#(String, String)), position: Vector, visible: Bool)
}

pub fn new() -> NodeLibrary {
  NodeLibrary(dict.new(), dict.new())
}

pub fn register_ints(lib: NodeLibrary, ints: List(IntNode)) -> NodeLibrary {
  ints
  |> map(fn(n: IntNode) { #(n.key, n) })
  |> dict.from_list
  |> fn(nodes) { NodeLibrary(..lib, ints: nodes) }
}

pub fn register_strings(
  lib: NodeLibrary,
  strings: List(StringNode),
) -> NodeLibrary {
  strings
  |> map(fn(n: StringNode) { #(n.key, n) })
  |> dict.from_list
  |> fn(nodes) { NodeLibrary(..lib, strings: nodes) }
}

fn keys(lib: NodeLibrary) -> List(#(String, String)) {
  let ints = dict.map_values(lib.ints, fn(_, _) { "int" }) |> dict.to_list
  let strings = dict.map_values(lib.strings, fn(_, _) { "string" }) |> dict.to_list

  ints
  |> list.append(strings)
  |> map(swap)
}

pub fn split_keypair(keypair: String) -> Result(#(String, String), Nil) {
  case string.split(keypair, ".") {
    [category, key] -> Ok(#(category, key))
    _ -> Error(Nil)
  }
}

pub fn generate_lib_menu(lib: NodeLibrary) -> LibraryMenu {
  lib
  |> keys
  |> fn(nodes) {
    LibraryMenu(nodes: nodes, position: Vector(0, 0), visible: False)
  }
}

pub fn get_int_node(lib: NodeLibrary, key: String) -> Result(IntNode, Nil) {
  io.debug(key)
  lib.ints
  |> dict.get(key)
}

pub fn get_string_node(lib: NodeLibrary, key: String) -> Result(StringNode, Nil) {
  io.debug(key)
  lib.strings
  |> dict.get(key)
}

pub fn get_node(lib: NodeLibrary, keypair: String) -> Result(Dynamic, Nil) {
  case split_keypair(keypair) {
    Ok(#("int", key)) -> get_int_node(lib, key) |> dynamic.from |> Ok
      // |> result.map(fn(n) { n.inputs })
      // |> result.unwrap(set.new())
    Ok(#("string", key)) -> get_string_node(lib, key) |> dynamic.from |> Ok
    Error(Nil) -> Error(Nil)
    _ -> Error(Nil)
  }
}
