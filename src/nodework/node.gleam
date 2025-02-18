import gleam/dict.{type Dict}
import gleam/int
import gleam/list.{filter, filter_map, index_map, map}
import gleam/pair
import gleam/set.{type Set}
import gleam/string

import nodework/math.{type Vector, Vector}
import nodework/util/random.{generate_random_id}

pub type Node {
  IntNode(
    key: String,
    label: String,
    inputs: List(String),
    func: fn(Dict(String, Int)) -> Int,
  )
  StringNode(
    key: String,
    label: String,
    inputs: List(String),
    func: fn(Dict(String, String)) -> String,
  )
  IntToStringNode(
    key: String,
    label: String,
    inputs: List(String),
    func: fn(Dict(String, Int)) -> String,
  )
}

pub type NodeError {
  NodeNotFound
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

pub type NodeIO {
  NodeOutput(id: UINodeOutputID)
  NodeInput(id: UINodeInputID)
}

pub type UINode {
  UINode(
    label: String,
    key: String,
    id: UINodeID,
    inputs: List(UINodeInput),
    output: UINodeOutput,
    position: Vector,
    offset: Vector,
  )
}

pub fn new_ui_node(node: Node, position: Vector) -> UINode {
  let id = case node.key {
    "output" -> "node-output"
    _ -> generate_random_id("node")
  }

  let ui_inputs =
    node.inputs
    |> index_map(fn(label, index) { new_ui_node_input(id, index, label) })

  UINode(
    label: node.label,
    key: node.key,
    id: id,
    inputs: ui_inputs,
    position: position,
    offset: Vector(0, 0),
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

pub fn set_output_hover(
  ins: Dict(UINodeID, UINode),
  id: UINodeOutputID,
) -> Dict(UINodeID, UINode) {
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

pub fn set_input_hover(
  ins: Dict(UINodeID, UINode),
  id: UINodeOutputID,
) -> Dict(UINodeID, UINode) {
  ins
  |> dict.map_values(fn(_, node) {
    node.inputs
    |> map(fn(input) {
      { input.id == id }
      |> fn(hovered) { UINodeInput(..input, hovered: hovered) }
    })
    |> fn(inputs) { UINode(..node, inputs: inputs) }
  })
}

pub fn reset_input_hover(ins: Dict(UINodeID, UINode)) -> Dict(UINodeID, UINode) {
  ins
  |> dict.map_values(fn(_, node) {
    node.inputs
    |> map(fn(input) { UINodeInput(..input, hovered: False) })
    |> fn(inputs) { UINode(..node, inputs: inputs) }
  })
}

pub fn set_hover(
  ins: Dict(UINodeID, UINode),
  kind: NodeIO,
  hover: Bool,
) -> Dict(UINodeID, UINode) {
  case kind, hover {
    NodeInput(id), True -> set_input_hover(ins, id)
    NodeInput(_), False -> reset_input_hover(ins)
    NodeOutput(id), True -> set_output_hover(ins, id)
    NodeOutput(_), False -> reset_output_hover(ins)
  }
}

pub fn get_ui_node(
  nodes: Dict(UINodeID, UINode),
  id: UINodeID,
) -> Result(UINode, Nil) {
  nodes
  |> dict.get(id)
}

pub fn update_all_node_offsets(
  nodes: Dict(UINodeID, UINode),
  point: Vector,
) -> Dict(UINodeID, UINode) {
  nodes
  |> dict.map_values(fn(_, n) { update_offset(n, point) })
}

pub fn update_offset(n: UINode, point: Vector) -> UINode {
  n.position
  |> math.vector_subtract(point)
  |> fn(p) { UINode(..n, offset: p) }
}

pub fn get_node_from_input_hovered(
  ins: Dict(UINodeID, UINode),
) -> Result(#(UINode, UINodeInput), NodeError) {
  ins
  |> dict.to_list
  |> map(pair.second)
  |> filter_map(fn(node) {
    case node.inputs |> filter(fn(in) { in.hovered }) {
      [] -> Error(Nil)
      [input] -> Ok(#(node, input))
      _ -> Error(Nil)
    }
  })
  |> fn(nodes) {
    case nodes {
      [node_and_input] -> Ok(node_and_input)
      [] -> Error(NodeNotFound)
      _ -> Error(NodeNotFound)
    }
  }
}

pub fn exclude_by_ids(
  nodes: Dict(UINodeID, UINode),
  ids: Set(UINodeID),
) -> Dict(UINodeID, UINode) {
  nodes
  |> dict.drop(set.to_list(ids))
}

pub fn extract_node_id(some id: String) -> UINodeID {
  id
  |> string.split(".")
  |> list.first
  |> fn(res) {
    case res {
      Ok(node_id) -> node_id
      Error(Nil) -> ""
    }
  }
}

pub fn extract_node_ids(some ids: List(String)) -> List(UINodeID) {
  ids
  |> map(extract_node_id)
  |> filter(fn(node_id) { node_id != "" })
}
