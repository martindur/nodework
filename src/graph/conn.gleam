import gleam/int.{to_string}
import gleam/list.{map}
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

pub fn update_active_connection_ends(conns: List(Conn), point: Vector) -> List(Conn) {
  conns
  |> map(fn(c) {
    case c.active {
      True -> Conn(..c, p1: point)
      False -> c
    }
  })
}
