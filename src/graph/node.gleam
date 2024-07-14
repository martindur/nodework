import gleam/int
import gleam/list.{filter, find, map}
import graph/vector.{type Vector, Vector}

pub type NodeId =
  Int

pub type NodeInputId =
  String

pub opaque type NodeInput {
  NodeInput(id: NodeInputId, label: String, hovered: Bool)
}

pub type NodeError {
  NotFound
}

pub fn new_input(id: NodeId, index: Int, label: String) -> NodeInput {
  { int.to_string(id) <> "-" <> int.to_string(index) }
  |> fn(input_id) { NodeInput(input_id, label, False) }
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

pub fn set_input_hover(ins: List(Node), id: NodeInputId) -> List(Node) {
  ins
  |> map(fn(node) {
    node.inputs
    |> map(fn(input) {
      { input.id == id }
      |> fn(hovered) { NodeInput(..input, hovered: hovered) }
    })
    |> fn(inputs) { Node(..node, inputs: inputs) }
  })
}

pub fn reset_input_hover(ins: List(Node)) -> List(Node) {
  ins
  |> map(fn(node) {
    node.inputs
    |> map(fn(input) { NodeInput(..input, hovered: False) })
    |> fn(inputs) { Node(..node, inputs: inputs) }
  })
}

pub fn get_node_from_input_hovered(ins: List(Node)) -> Result(Node, NodeError) {
  ins
  |> filter(fn(node) {
    case node.inputs |> filter(fn(in) { in.hovered }) {
      [] -> False
      _ -> True
    }
  })
  |> list.first
  |> fn(res: Result(Node, Nil)) {
    case res {
      Ok(node) -> Ok(node)
      Error(Nil) -> Error(NotFound)
    }
  }
}

// pub type NodeOutput {
//   Shape
//   String
// }

// pub type NodeUI {
//   NodeUI(title: String, inputs: List(NodeInput), output: NodeOutput)
// }

pub type Node {
  Node(
    position: Vector,
    offset: Vector,
    id: NodeId,
    inputs: List(NodeInput),
    name: String,
  )
}

pub fn get_position(nodes: List(Node), id: NodeId) -> Vector {
  nodes
  |> find(fn(n) { n.id == id })
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

pub fn update_all_node_offsets(nodes: List(Node), point: Vector) -> List(Node) {
  nodes
  |> map(update_offset(_, point))
}
