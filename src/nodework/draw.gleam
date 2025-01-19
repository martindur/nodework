import gleam/dict
import gleam/list.{filter, map}
import gleam/pair
import gleam/set

import nodework/conn.{type Conn, Conn}
import nodework/draw/viewbox.{type ViewBox, ViewBox}
import nodework/math.{type Vector, Vector}
import nodework/model.{type Model, DragMode, Model, NormalMode, UIGraph}
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
  |> dict.take(m.graph.nodes, _)
  |> dict.map_values(fn(_key, node) {
    case m.mouse_down {
      False -> node
      True ->
        UINode(..node, position: math.vector_subtract(node.offset, m.cursor))
    }
  })
  |> dict.merge(m.graph.nodes, _)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
}

pub fn dragged_connection(m: Model) -> Model {
  let point = fn(p) { viewbox.translate(m.viewbox, p) }

  m.graph.connections
  |> map(fn(c) {
    case c.dragged {
      True -> Conn(..c, p1: point(m.cursor))
      False -> c
    }
  })
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
}

fn order_connection_nodes(nodes: List(UINode), c: Conn) -> List(UINode) {
  case list.first(nodes) {
    Error(Nil) -> []
    Ok(n) ->
      case n.id == node.extract_node_id(c.from) {
        True -> nodes
        False -> list.reverse(nodes)
      }
  }
}

pub fn connections(m: Model) -> Model {
  m.graph.connections
  |> map(fn(c) {
    dict.take(m.graph.nodes, node.extract_node_ids([c.from, c.to]))
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
              |> filter(fn(in) { in.id == c.to })
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
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
}
