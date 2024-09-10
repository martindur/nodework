import gleam/set
import gleeunit/should

import nodework/math.{Vector}
import nodework/node.{type Node, IntNode, UINode}

fn simple_node() -> Node {
  IntNode("one", "One", set.from_list([]), fn(_) { 1 })
}

pub fn update_offset__from_origin__test() {
  let data =
    simple_node()
    |> node.new_ui_node(Vector(0, 0))
    |> fn(n) { UINode(..n, offset: Vector(10, 10)) }

  let expected = UINode(..data, offset: Vector(5, 5))

  data
  |> node.update_offset(Vector(5, 5))
  |> should.equal(expected)
}

pub fn update_offset__from_negative__test() {
  let data =
    simple_node()
    |> node.new_ui_node(Vector(-10, -10))
    |> fn(n) { UINode(..n, offset: Vector(9999, 9999)) }

  let expected = UINode(..data, offset: Vector(20, 20))

  data
  |> node.update_offset(Vector(10, 10))
  |> should.equal(expected)
}
