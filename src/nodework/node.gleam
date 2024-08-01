import gleam/dict.{type Dict}
import gleam/int
import gleam/list.{index_map, map}
import gleam/set.{type Set}
import gleam/string.{capitalise, split}

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

pub type UINodeID =
  String

pub type UINodeOutputID =
  String

pub type UINodeInputID =
  String

pub type UINodeInput {
  UINodeInput(id: UINodeInputID, position: Vector, label: String, hovered: Bool)
}

pub type UINodeOutput {
  UINodeOutput(id: UINodeOutputID, position: Vector, hovered: Bool)
}

pub type UINode {
  UINode(
    label: String,
    key: String,
    id: UINodeID,
    inputs: List(UINodeInput),
    output: UINodeOutput,
    position: Vector,
  )
}

pub fn new_ui_node(key: String, inputs: Set(String), position: Vector) -> UINode {
  let label = case split(key, ".") {
    [_, text] -> text
    _ -> key
  }

  let id = generate_random_id("node")

  let ui_inputs =
    inputs
    |> set.to_list
    |> index_map(fn(label, index) { new_ui_node_input(id, index, label) })

  UINode(
    label: capitalise(label),
    key: key,
    id: id,
    inputs: ui_inputs,
    position: position,
    output: new_ui_node_output(id),
  )
}

fn input_position_from_index(index: Int) -> Vector {
  Vector(0, 50 + index * 30)
}

fn new_ui_node_input(id: UINodeID, index: Int, label: String) -> UINodeInput {
  [id, "in", int.to_string(index)]
  |> string.join(".")
  |> fn(input_id) {
    UINodeInput(input_id, input_position_from_index(index), label, False)
  }
}

fn new_ui_node_output(id: UINodeID) -> UINodeOutput {
  UINodeOutput(
    id <> ".out",
    Vector(200, 50),
    // NOTE: For now we just have a single output, which sits the same place. We might want to change it if node needs to be wider
    False,
  )
}

pub fn set_output_hover(ins: Dict(UINodeID, UINode), id: UINodeOutputID) -> Dict(UINodeID, UINode) {
  ins
  |> dict.map_values(fn(_, node) {
    case node.output.id == id {
      True -> UINodeOutput(..node.output, hovered: True)
      False -> node.output
    }
    |> fn(output) { UINode(..node, output: output) }
  })
}

pub fn reset_output_hover(ins: Dict(UINodeID, UINode)) -> Dict(UINodeID, UINode) {
  ins
  |> dict.map_values(fn(_, node) {
    UINodeOutput(..node.output, hovered: False)
    |> fn(output) { UINode(..node, output: output) }
  })
}

pub fn get_node(nodes: Dict(UINodeID, UINode), id: UINodeID) -> Result(UINode, Nil) {
  nodes
  |> dict.get(id)
}
