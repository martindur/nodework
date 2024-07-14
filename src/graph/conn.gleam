import gleam/int.{to_string}
import gleam/list.{any}
import lustre/attribute.{type Attribute, attribute as attr}

import graph/vector.{type Vector}

pub type Conn {
  Conn(p0: Vector, p1: Vector, node_0_id: Int, node_1_id: Int, active: Bool)
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
  a.node_0_id == b.node_0_id && a.node_1_id == b.node_1_id
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

pub fn deduplicate(conns: List(Conn)) -> List(Conn) {
  deduplicate_helper(conns, [])
}
