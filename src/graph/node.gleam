import gleam/int
import graph/vector.{type Vector}

pub type NodeId =
  Int

// pub type NodeInput {
//   Shape
//   String
// }

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
    inputs: List(String),
    name: String,
  )
}

/// Update a Node offset vector by subtracting its current position with a given point
pub fn update_offset(node: Node, point: Vector) -> Node {
  Node(..node, offset: vector.subtract(node.position, point))
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
