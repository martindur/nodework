import gleam/dict
import gleam/list.{filter, map}
import gleam/pair
import gleam/set

import nodework/conn.{type Conn, Conn}
import nodework/draw/viewbox.{type ViewBox, ViewBox}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, DragMode, Model, NormalMode,
}
import nodework/node.{type UINode, type UINodeInput, UINode}

pub fn cursor(m: Model, p: Vector) -> Model {
  p
  |> viewbox.scale(m.viewbox, _)
  |> fn(cursor) { Model(..m, cursor: cursor) }
}

pub fn viewbox_offset(m: Model, limit: Int) -> Model {
  case m.mode {
    NormalMode -> m.viewbox.offset
    DragMode ->
      m.cursor
      |> math.vector_subtract(m.last_clicked_point, _)
      |> math.vector_inverse
      |> math.bounded_vector(limit)
  }
  |> fn(offset) { ViewBox(..m.viewbox, offset: offset) }
  |> fn(vb) { Model(..m, viewbox: vb) }
}

pub fn nodes(m: Model) -> Model {
  m.nodes_selected
  |> set.to_list
  |> dict.take(m.nodes, _)
  |> dict.map_values(fn(_key, node) {
    case m.mouse_down {
      False -> node
      True ->
        UINode(..node, position: math.vector_subtract(node.offset, m.cursor))
    }
  })
  |> dict.merge(m.nodes, _)
  |> fn(nodes) { Model(..m, nodes: nodes) }
}

pub fn dragged_connection(m: Model) -> Model {
  let point = fn(p) { viewbox.translate(m.viewbox, p) }

  m.connections
  |> map(fn(c) {
    case c.dragged {
      True -> Conn(..c, p1: point(m.cursor))
      False -> c
    }
  })
  |> fn(conns) { Model(..m, connections: conns) }
}

fn order_connection_nodes(nodes: List(UINode), c: Conn) -> List(UINode) {
  case list.first(nodes) {
    Error(Nil) -> []
    Ok(node) ->
      case node.id == c.source_node_id {
        True -> nodes
        False -> list.reverse(nodes)
      }
  }
}

pub fn connections(m: Model) -> Model {
  m.connections
  |> map(fn(c) {
    dict.take(m.nodes, [c.source_node_id, c.target_node_id])
    |> dict.to_list
    |> map(pair.second)
    |> order_connection_nodes(c)
    |> fn(nodes: List(UINode)) {
      case nodes {
        [] -> c
        [_] -> c
        [a, b] ->
          Conn(
            ..c,
            p0: math.vector_add(a.position, a.output.position),
            p1: b.inputs
              |> filter(fn(in) { in.id == c.target_input_id })
              |> fn(nodes) {
                let assert [x] = nodes
                x
              }
              |> fn(x: UINodeInput) { x.position }
              |> math.vector_add(b.position, _),
          )
        _ -> c
      }
    }
  })
  |> fn(conns) { Model(..m, connections: conns) }
}

pub fn delete_selected_nodes(model: Model) -> Model {
  todo
}

pub fn delete_orphaned_connections(model: Model) -> Model {
  todo
}
