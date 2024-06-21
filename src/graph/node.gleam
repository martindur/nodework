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

pub fn update_offset(node: Node, point: Vector) -> Node {
  Node(..node, offset: vector.subtract(node.position, point))
}
