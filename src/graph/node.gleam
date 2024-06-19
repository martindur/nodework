import graph/vector.{type Vector}

pub type NodeId =
  Int

pub type Node {
  Node(position: Vector, offset: Vector, id: NodeId)
}


pub fn update_offset(node: Node, point: Vector) -> Node {
  Node(..node, offset: vector.subtract(node.position, point))
}
