import gleam/set
import gleeunit/should

import nodework/math.{Vector}
import nodework/node.{UINode}

pub fn update_offset__from_origin__test() {
  let data =
    node.new_ui_node("foo", set.from_list([]), Vector(0, 0))
    |> fn(n) { UINode(..n, offset: Vector(10, 10)) }

  let expected = UINode(..data, offset: Vector(5, 5))

  // UINode(
  //   label: "foo",
  //   id: "foo",
  //   key: "some.foo",
  //   inputs: [],
  //   output: node.new_ui_node_output("foo"),
  //   Vector(0, 0),
  //   Vector(10, 10),
  // )
  data
  |> node.update_offset(Vector(5, 5))
  |> should.equal(expected)
  // |> should.equal(Node(
  //   Vector(0, 0),
  //   Vector(5, 5),
  //   id: "foo",
  //   inputs: [],
  //   output: node.new_output("foo"),
  //   name: "foo",
  // ))
}

pub fn update_offset__from_negative__test() {
  let data =
    node.new_ui_node("foo", set.from_list([]), Vector(-10, -10))
    |> fn(n) { UINode(..n, offset: Vector(9999, 9999)) }

  let expected = UINode(..data, offset: Vector(20, 20))

  data
  |> node.update_offset(Vector(10, 10))
  |> should.equal(expected)
  // Node(
  //   Vector(-10, -10),
  //   Vector(9999, 9999),
  //   id: "boo",
  //   inputs: [node.new_input("boo", 0, "foo"), node.new_input("boo", 1, "bar")],
  //   output: node.new_output("boo"),
  //   name: "baz",
  // )
  // |> node.update_offset(Vector(10, 10))
  // |> should.equal(Node(
  //   Vector(-10, -10),
  //   Vector(20, 20),
  //   id: "boo",
  //   inputs: [node.new_input("boo", 0, "foo"), node.new_input("boo", 1, "bar")],
  //   output: node.new_output("boo"),
  //   name: "baz",
  // ))
}
