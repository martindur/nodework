import gleam/list.{filter, map, concat}
import gleam/dict
import gleam/set
import gleam/pair
import graph/model.{type Model, Model}
import graph/node.{type Node, Node}
import graph/navigator.{type Navigator, Navigator}
import graph/vector.{type Vector, Vector}
import graph/viewbox.{ViewBox, Normal, Drag}
import graph/conn.{type Conn, Conn}

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
  m.nodes_selected
  |> set.to_list
  |> dict.take(m.nodes, _)
  |> dict.map_values(fn(_key, node) {
    case m.navigator.mouse_down {
      False -> node
      True -> Node(..node, position: vector.subtract(node.offset, m.navigator.cursor_point))
    }
  })
  |> dict.merge(m.nodes, _)
  |> fn(nodes) { Model(..m, nodes: nodes) }

  // let is_selected = fn(node: Node) { set.contains(m.nodes_selected, node.id) }
  // let unselected = m.nodes |> dict.filter(fn(_, x) { !is_selected(x) })

  // m.nodes
  // |> dict.filter(is_selected)
  // |> map(fn(node) {
  //   case m.navigator.mouse_down {
  //     False -> node
  //     True -> Node(..node, position: vector.subtract(node.offset, m.navigator.cursor_point))
  //   }
  // })
  // |> fn(nodes) { [unselected, nodes] |> concat }
  // |> fn(nodes) { Model(..m, nodes: nodes) }
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

fn order_connection_nodes(nodes: List(Node), c: Conn) -> List(Node) {
  case list.first(nodes) {
    Error(Nil) -> []
    Ok(node) ->
      case node.id == c.node_0_id {
        True -> nodes
        False -> list.reverse(nodes)
      }
  }
}

pub fn connections(m: Model) -> Model {
  let offset = Vector(200, 50) // TODO: Add actual positions to inputs/output
  let input_offset = Vector(0, 50)

  m.connections
  |> map(fn(c) {
    dict.take(m.nodes, [c.node_0_id, c.node_1_id])
    |> dict.to_list
    |> map(pair.second)
    |> order_connection_nodes(c)
    |> fn(nodes: List(Node)) {
      case nodes {
        [] -> c
        [_] -> c
        [a, b] -> Conn(..c, p0: vector.add(a.position, offset), p1: vector.add(b.position, input_offset))
        _ -> c
      }
    }
  })
  |> fn (conns) { Model(..m, connections: conns) }
}

