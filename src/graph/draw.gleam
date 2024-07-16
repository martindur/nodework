import gleam/dict
import gleam/list.{concat, filter, map}
import gleam/pair
import gleam/set
import graph/conn.{type Conn, Conn}
import graph/model.{type Model, Model}
import graph/navigator.{type Navigator, Navigator}
import graph/node.{type Node, type NodeInput, Node}
import graph/vector.{type Vector, Vector}
import graph/viewbox.{Drag, Normal, ViewBox}

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
      True ->
        Node(
          ..node,
          position: vector.subtract(node.offset, m.navigator.cursor_point),
        )
    }
  })
  |> dict.merge(m.nodes, _)
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
        [a, b] ->
          Conn(
            ..c,
            p0: vector.add(a.position, node.output_position(a.output)),
            p1: b.inputs
              |> filter(fn(in) { node.input_id(in) == c.node_input_id })
              |> fn(nodes) {
                let assert [x] = nodes
                x
              }
              |> fn(x: NodeInput) { node.input_position(x) }
              |> vector.add(b.position, _),
          )
        _ -> c
      }
    }
  })
  |> fn(conns) { Model(..m, connections: conns) }
}
