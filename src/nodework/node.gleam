import gleam/string.{capitalise, split}
import gleam/dict.{type Dict}
import gleam/set.{type Set}

import nodework/math.{type Vector}
import nodework/util/random.{generate_random_id}

pub type IntNode {
  IntNode(
    key: String,
    inputs: Set(String),
    output: fn(Dict(String, Int)) -> Int,
  )
}

pub type StringNode {
  StringNode(
    key: String,
    inputs: Set(String),
    output: fn(Dict(String, String)) -> String,
  )
}

pub type UINodeID = String

pub type UINode {
  UINode(label: String, key: String, id: UINodeID, inputs: Set(String), position: Vector)
}

pub fn new_ui_node(key: String, inputs: Set(String), position: Vector) -> UINode {
  let label = case split(key, ".") {
    [_, text] -> text
    _ -> key
  }

  UINode(label: capitalise(label), key: key, id: generate_random_id("node"), inputs: inputs, position: position)
}


