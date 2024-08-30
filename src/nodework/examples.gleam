import gleam/dict.{type Dict}
import gleam/set
import gleam/string

import nodework/lib.{type NodeLibrary}
import nodework/node.{IntNode, StringNode}

fn add(inputs: Dict(String, Int)) -> Int {
  case dict.get(inputs, "a"), dict.get(inputs, "b") {
    Ok(a), Ok(b) -> {
      a + b
    }
    Ok(a), Error(_) -> a
    Error(_), Ok(b) -> b
    _, _ -> 0
  }
}

fn double(inputs: Dict(String, Int)) -> Int {
  case dict.get(inputs, "a") {
    Ok(a) -> {
      a * 2
    }
    _ -> 0
  }
}

fn capitalise(inputs: Dict(String, String)) -> String {
  case dict.get(inputs, "text") {
    Ok(text) -> string.capitalise(text)
    Error(_) -> ""
  }
}

fn ten(_inputs: Dict(String, Int)) -> Int {
  10
}

fn output(inputs: Dict(String, String)) -> String {
  case dict.get(inputs, "out") {
    Ok(out) -> out
    Error(_) -> ""
  }
}

pub fn example_nodes() -> NodeLibrary {
  // let int_nodes = [
  //   IntNode("add", set.from_list(["a", "b"]), add),
  //   IntNode("double", set.from_list(["a"]), double),
  //   IntNode("ten", set.from_list([]), ten)
  // ]
  // let string_nodes = [
  //   StringNode("capitalise", set.from_list(["text"]), capitalise),
  //   StringNode("output", set.from_list(["out"]), output),
  // ]

  let nodes = [
    IntNode("add", "Add", set.from_list(["a", "b"]), add),
    IntNode("double", "Double", set.from_list(["a"]), double),
    IntNode("ten", "Ten", set.from_list([]), ten),
    StringNode("capitalise", "Capitalise", set.from_list(["text"]), capitalise),
    StringNode("output", "Output", set.from_list(["out"]), output),
  ]

  lib.register_nodes(nodes)
  // |> lib.register_ints(int_nodes)
  // |> lib.register_strings(string_nodes)
}
