import gleam/int.{to_string}
import gleam/list.{any, filter}
import gleam/set.{type Set}

import lustre/attribute.{type Attribute, attribute as attr}
import nodework/math.{type Vector}
import nodework/node.{type UINodeID, type UINodeInputID, type UINodeOutputID}

pub type Conn {
  Conn(
    id: ConnID,
    p0: Vector,
    p1: Vector,
    from: UINodeOutputID,
    to: UINodeInputID,
    // target_node_id: String,
    value: String,
    dragged: Bool,
  )
}

pub type ConnID = String

pub fn to_attributes(conn: Conn) -> List(Attribute(a)) {
  [
    attr("x1", to_string(conn.p0.x)),
    attr("y1", to_string(conn.p0.y)),
    attr("x2", to_string(conn.p1.x)),
    attr("y2", to_string(conn.p1.y)),
  ]
}

fn conn_duplicate(a: Conn, b: Conn) -> Bool {
  // an input can only hold a single connection
  a.to == b.to
}

fn deduplicate_helper(remaining: List(Conn), seen: List(Conn)) -> List(Conn) {
  case remaining {
    [] -> seen
    [head, ..tail] -> {
      case any(seen, fn(x) { conn_duplicate(x, head) }) {
        True -> deduplicate_helper(tail, seen)
        False -> deduplicate_helper(tail, [head, ..seen])
      }
    }
  }
}

pub fn unique(conns: List(Conn)) -> List(Conn) {
  deduplicate_helper(conns, [])
}

pub fn map_dragged(conns: List(Conn), f: fn(Conn) -> Conn) {
  conns
  |> list.map(fn(c) {
    case c.dragged {
      False -> c
      True -> f(c)
    }
  })
}

pub fn exclude_by_node_ids(conns: List(Conn), ids: Set(String)) -> List(Conn) {
  conns
  |> filter(fn(c) {
    node.extract_node_ids([c.from, c.to])
    |> set.from_list
    |> set.intersection(ids)
    |> set.to_list
    |> fn(x) {
      case x {
        [] -> True
        _ -> False
      }
    }
  })
}
