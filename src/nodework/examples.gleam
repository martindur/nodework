import gleam/dict.{type Dict}
import gleam/int
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

fn rect(_inputs: Dict(String, String)) -> String {
  "<rect width='100' height='100' rx='15' x='50%' y='50%' class='fill-red-400' />"
}

fn circle(_: Dict(String, String)) -> String {
  "<circle cx='50%' cy='50%' r='50' class='fill-blue-200' />"
}


fn combine(inputs: Dict(String, String)) -> String {
  case dict.get(inputs, "top"), dict.get(inputs, "bottom") {
    Ok(a), Ok(b) -> { b <> "\n" <> a }
    Ok(a), Error(_) -> a
    Error(_), Ok(b) -> b
    _, _ -> ""
  }
}

fn output(inputs: Dict(String, String)) -> String {
  case dict.get(inputs, "out") {
    Ok(out) -> out
    Error(_) -> ""
  }
  |> fn(body) {
    "<svg width='100%' height='100%' xmlns='http://www.w3.org/2000/svg'>"
      <> body <>
    "</svg>"
  }
}

pub fn example_nodes() -> NodeLibrary {
  let nodes = [
    IntNode("add", "Add", ["a", "a"], add),
    IntNode("double", "Double", ["a"], double),
    IntNode("ten", "Ten", [], ten),
    StringNode("bob", "Bob", [], bob),
    StringNode("cap", "Cap", ["text"], capitalise),
    StringNode("rect", "Rect", [], rect),
    StringNode("circle", "Circle", [], circle),
    StringNode("combine", "Combine", ["top", "bottom"], combine),
    StringNode("output", "Output", ["out"], output),
    IntToStringNode(
      "int_to_string",
      "Int to String",
      ["int"],
      int_to_string,
    ),
  ]

  lib.register_nodes(nodes)
}
