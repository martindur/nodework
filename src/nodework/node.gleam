import gleam/string.{capitalise, split}
import gleam/dict.{type Dict}
import gleam/set.{type Set}

import nodework/math.{type Vector, Vector}
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


pub type UINodeOutput {
  UINodeOutput(id: String, position: Vector, hovered: Bool)
}

pub type UINode {
  UINode(
    label: String,
    key: String,
    id: UINodeID,
    inputs: Set(String),
    output: UINodeOutput,
    position: Vector
  )
}

pub fn new_ui_node(key: String, inputs: Set(String), position: Vector) -> UINode {
  let label = case split(key, ".") {
    [_, text] -> text
    _ -> key
  }

  let id = generate_random_id("node")

  UINode(
    label: capitalise(label),
    key: key,
    id: id,
    inputs: inputs,
    position: position,
    output: new_ui_node_output(id)
  )
}

pub fn new_ui_node_output(id: UINodeID) -> UINodeOutput {
  UINodeOutput(
    id <> ".out",
    Vector(200, 50),
    // NOTE: For now we just have a single output, which sits the same place. We might want to change it if node needs to be wider
    False
  )
}
