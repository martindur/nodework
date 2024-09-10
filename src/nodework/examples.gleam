import gleam/dict.{type Dict}
import gleam/int
import gleam/set
import gleam/string

import nodework/lib.{type NodeLibrary}
import nodework/node.{IntNode, IntToStringNode, StringNode}

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

fn bob(_inputs: Dict(String, String)) -> String {
  "bob"
}

fn int_to_string(inputs: Dict(String, Int)) -> String {
  case dict.get(inputs, "int") {
    Ok(num) -> int.to_string(num)
    Error(_) -> ""
  }
}

fn output(inputs: Dict(String, String)) -> String {
  case dict.get(inputs, "out") {
    Ok(out) -> out
    Error(_) -> ""
  }
}

pub fn example_nodes() -> NodeLibrary {
  let nodes = [
    IntNode("add", "Add", set.from_list(["a", "b"]), add),
    IntNode("double", "Double", set.from_list(["a"]), double),
    IntNode("ten", "Ten", set.from_list([]), ten),
    StringNode("capitalise", "Capitalise", set.from_list(["text"]), capitalise),
    StringNode("bob", "Bob", set.from_list([]), bob),
    StringNode("output", "Output", set.from_list(["out"]), output),
    IntToStringNode(
      "int_to_string",
      "Int to String",
      set.from_list(["int"]),
      int_to_string,
    ),
  ]

  lib.register_nodes(nodes)
}
