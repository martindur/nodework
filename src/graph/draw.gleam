import gleam/list.{filter, map, concat}
import gleam/set
import graph/model.{type Model, Model}
import graph/node.{type Node, Node}
import graph/navigator.{type Navigator, Navigator}
import graph/vector.{type Vector}
import graph/viewbox.{ViewBox, Normal, Drag}
import graph/conn.{Conn}

pub fn cursor_point(m: Model, p: Vector) -> Model {
  p
  |> viewbox.to_viewbox_scale(m.viewbox, _)
  |> fn(p) { Navigator(..m.navigator, cursor_point: p) }
  |> fn(nav) { Model(..m, navigator: nav) }
}

pub fn viewbox_offset(m: Model, limit: Int) -> Model {
  case m.mode {
    Normal -> m.viewbox.offset
    Drag ->
      m.navigator.cursor_point
      |> vector.subtract(m.last_clicked_point, _)
      |> vector.inverse
      |> vector.bounded_vector(limit)
  }
  |> fn(offset) { ViewBox(..m.viewbox, offset: offset) }
  |> fn(vb) { Model(..m, viewbox: vb) }
}

pub fn node_positions(m: Model) -> Model {
  let is_selected = fn(node: Node) { set.contains(m.nodes_selected, node.id) }
  let unselected = m.nodes |> filter(fn(x) { !is_selected(x) })

  m.nodes
  |> filter(is_selected)
  |> map(fn(node) {
    case m.navigator.mouse_down {
      False -> node
      True -> Node(..node, position: vector.subtract(node.offset, m.navigator.cursor_point))
    }
  })
  |> fn(nodes) { [unselected, nodes] |> concat }
  |> fn(nodes) { Model(..m, nodes: nodes) }
}

pub fn dragged_connection(m: Model) -> Model {
  let point = fn(p) { viewbox.to_viewbox_translate(m.viewbox, p) }

  m.connections
  |> map(fn(c) {
    case c.active {
      True -> Conn(..c, p1: point(m.navigator.cursor_point))
      False -> c
    }
  })
  |> fn(conns) { Model(..m, connections: conns) }
}



