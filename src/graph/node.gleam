import gleam/io
import gleam/list.{filter, map}
import gleam/set.{type Set}
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


pub fn update_node_positions(nodes: List(Node), selected: Set(NodeId), mouse_down: Bool, cursor_point: Vector) -> List(Node) {
  let is_selected = fn(node: Node) {
    set.contains(selected, node.id)
  }
  let unselected = nodes |> filter(fn(x) { !is_selected(x) })

  nodes
  |> filter(is_selected)
  |> map(fn(node) {
    case mouse_down {
      False -> node
      True ->
        Node(
          ..node,
          position: vector.subtract(node.offset, cursor_point),
        )
    }
  })
  |> fn(nodes) { [unselected, nodes] |> list.concat }
}
