import gleam/dict
import gleam/int.{to_string}
import gleam/list.{any, filter}
import gleam/set.{type Set}
import lustre/attribute.{type Attribute, attribute as attr}

import nodework/vector.{type Vector}

pub type Conn {
  Conn(
    id: String,
    p0: Vector,
    p1: Vector,
    source_node_id: String,
    target_node_id: String,
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

pub fn exclude_by_node_ids(conns: List(Conn), ids: Set(String)) -> List(Conn) {
  conns
  |> filter(fn(c) {
    set.from_list([c.source_node_id, c.target_node_id])
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

// fn calculate_connection(conns: List(Conn), c: Conn) -> List(String) {
//   conns
//   |> filter(fn(c2) { c.source_node_id == c2.target_node_id })
//   |> fn(cns) {
//     case cns {
//       [] -> dict.from_list([#(c.target_node_id, c.source_node_id)])
//       _ ->
//         list.map(cns, fn(c2) { calculate_connection(conns, c2) })
//         |> fn(res) { dict.from_list([#(c.target_node_id, res)]) }
//     }
//   }
// }

// pub fn generate_graph(conns: List(Conn)) -> List(String) {
//   conns
//   |> filter(fn(c) { c.id == "output-node-0" })
//   |> fn(cs) {
//     case cs {
//       [root] -> calculate_connection(conns, root)
//       _ -> []
//     }
//   }
// }
