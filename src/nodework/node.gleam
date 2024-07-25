import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list.{filter, filter_map, map}
import gleam/pair
import gleam/set.{type Set}
import gleam/string
import nodework/vector.{type Vector, Vector}
import util/random

pub type Node {
  Node(
    position: Vector,
    offset: Vector,
    id: NodeId,
    inputs: List(NodeInput),
    output: NodeOutput,
    name: String,
  )
}

pub type NodeFunction {
  NodeFunction(
    label: String,
    inputs: Set(String),
    output: fn(Dict(String, Dynamic)) -> Dynamic,
  )
}

pub type NodeId =
  String

pub type NodeError {
  NotFound
}

pub type NodeInputId =
  String

pub type NodeOutputId =
  String

pub opaque type NodeInput {
  NodeInput(id: NodeInputId, position: Vector, label: String, hovered: Bool)
}

pub opaque type NodeOutput {
  NodeOutput(id: NodeOutputId, position: Vector, hovered: Bool)
}

fn input_position_from_index(index: Int) -> Vector {
  Vector(0, 50 + index * 30)
}

pub fn new_input(id: NodeId, index: Int, label: String) -> NodeInput {
  { id <> "-" <> int.to_string(index) }
  |> fn(input_id) {
    NodeInput(input_id, input_position_from_index(index), label, False)
  }
}

pub fn input_id(in: NodeInput) -> String {
  in.id
}

pub fn input_label(in: NodeInput) -> String {
  in.label
}

pub fn input_hovered(in: NodeInput) -> Bool {
  in.hovered
}

pub fn input_position(in: NodeInput) -> Vector {
  in.position
}

pub fn set_input_hover(
  ins: Dict(NodeId, Node),
  id: NodeInputId,
) -> Dict(NodeId, Node) {
  ins
  |> dict.map_values(fn(_, node) {
    node.inputs
    |> map(fn(input) {
      { input.id == id }
      |> fn(hovered) { NodeInput(..input, hovered: hovered) }
    })
    |> fn(inputs) { Node(..node, inputs: inputs) }
  })
}

pub fn reset_input_hover(ins: Dict(NodeId, Node)) -> Dict(NodeId, Node) {
  ins
  |> dict.map_values(fn(_, node) {
    node.inputs
    |> map(fn(input) { NodeInput(..input, hovered: False) })
    |> fn(inputs) { Node(..node, inputs: inputs) }
  })
}

pub fn set_output_hover(
  ins: Dict(NodeId, Node),
  id: NodeOutputId,
) -> Dict(NodeId, Node) {
  ins
  |> dict.map_values(fn(_, node) {
    case node.output.id == id {
      True -> NodeOutput(..node.output, hovered: True)
      False -> node.output
    }
    |> fn(output) { Node(..node, output: output) }
  })
}

pub fn reset_output_hover(ins: Dict(NodeId, Node)) -> Dict(NodeId, Node) {
  ins
  |> dict.map_values(fn(_, node) {
    NodeOutput(..node.output, hovered: False)
    |> fn(output) { Node(..node, output: output) }
  })
}

pub fn get_node_from_input_hovered(
  ins: Dict(NodeId, Node),
) -> Result(#(Node, NodeInput), NodeError) {
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
      [] -> Error(NotFound)
      _ -> Error(NotFound)
    }
  }
}

pub fn new_output(id: NodeId) -> NodeOutput {
  NodeOutput(
    "out-" <> id,
    Vector(200, 50),
    // NOTE: For now we just have a single output, which sits the same place. We might want to change it if node needs to be wider
    False,
  )
}

pub fn output_position(out: NodeOutput) -> Vector {
  out.position
}

pub fn output_id(out: NodeOutput) -> NodeOutputId {
  out.id
}

pub fn output_hovered(out: NodeOutput) -> Bool {
  out.hovered
}

pub fn positions_from_ids(nodes: List(Node), ids: List(NodeId)) {
  nodes
  |> filter(fn(node) { list.contains(ids, node.id) })
  |> map(fn(node) { node.position })
}

pub fn get_position(nodes: Dict(NodeId, Node), id: NodeId) -> Vector {
  nodes
  |> dict.get(id)
  |> fn(r: Result(Node, Nil)) {
    case r {
      Ok(n) -> n.position
      Error(Nil) -> Vector(0, 0)
    }
  }
}

/// Update a Node offset vector by subtracting its current position with a given point
pub fn update_offset(node: Node, point: Vector) -> Node {
  node.position
  |> vector.subtract(point)
  |> fn(p) { Node(..node, offset: p) }
}

pub fn scale_offset(node: Node, scalar: Float) -> Node {
  node.offset
  |> vector.scalar(scalar)
  |> fn(offset) { Node(..node, offset: offset) }
}

pub fn scale_position(node: Node, scalar: Float) -> Node {
  node.position
  |> vector.scalar(scalar)
  |> fn(pos) { Node(..node, position: pos) }
}

pub fn update_all_node_offsets(
  nodes: Dict(NodeId, Node),
  point: Vector,
) -> Dict(NodeId, Node) {
  nodes
  |> dict.map_values(fn(_, node) { update_offset(node, point) })
}

pub fn filter_by_ids(
  nodes: Dict(NodeId, Node),
  ids: Set(NodeId),
) -> Dict(NodeId, Node) {
  nodes
  |> dict.take(set.to_list(ids))
}

pub fn exclude_by_ids(
  nodes: Dict(NodeId, Node),
  ids: Set(NodeId),
) -> Dict(NodeId, Node) {
  nodes
  |> dict.drop(set.to_list(ids))
}

pub fn new_node(
  library: Dict(String, NodeFunction),
  identifier: String,
  position: Vector,
) -> Result(Node, Nil) {
  library
  |> dict.get(identifier)
  |> fn(res: Result(NodeFunction, Nil)) {
    case res {
      Error(Nil) -> Error(Nil)
      Ok(node_function) -> {
        let id = random.generate_random_id("node")

        Ok(Node(
          position: position,
          offset: Vector(0, 0),
          id: id,
          name: string.capitalise(node_function.label),
          output: new_output(id),
          inputs: node_function.inputs
            |> set.to_list
            |> list.index_map(fn(label, i) { new_input(id, i, label) }),
        ))
      }
    }
  }
}

pub fn output_node(position: Vector) -> Result(Node, Nil) {
  Ok(
    Node(
      position: position,
      offset: Vector(0, 0),
      id: "output-node",
      name: "Output",
      output: new_output("output-node"),
      inputs: [new_input("output-node", 0, "eval")],
    ),
  )
}
