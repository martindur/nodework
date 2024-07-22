import gleam/int.{to_string}
import gleam/list.{any}
import lustre/attribute.{type Attribute, attribute as attr}

import nodework/vector.{type Vector}

pub type Conn {
  Conn(
    id: String,
    p0: Vector,
    p1: Vector,
    source_node_id: Int,
    target_node_id: Int,
    target_input_id: String,
    active: Bool,
  )
}

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
  a.target_input_id == b.target_input_id
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

pub fn map_active(conns: List(Conn), f: fn(Conn) -> Conn) {
  conns
  |> list.map(fn(c) {
    case c.active {
      False -> c
      True -> f(c)
    }
  })
}
