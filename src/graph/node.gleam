import graph/position.{type Position}
import graph/navigator.{type Navigator}

pub type NodeId =
  Int

pub type Node {
  Node(position: Position, id: NodeId)
}

// TODO: Maybe do this in navigator module?
// It's really just calculating a Point where the start point varies (e.g. depending on the node)
// This is not really "node" logic, but more navigator logic.
pub fn calc_position(node: Node, navigator: Navigator) -> Node {
}
