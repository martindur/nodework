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

pub fn example_nodes() -> NodeLibrary {
  let int_nodes = [
    IntNode("add", set.from_list(["a", "b"]), add),
    IntNode("double", set.from_list(["a"]), double),
  ]
  let string_nodes = [
    StringNode("capitalise", set.from_list(["text"]), capitalise),
  ]

  lib.new()
  |> lib.register_ints(int_nodes)
  |> lib.register_strings(string_nodes)
}
