import gleeunit/should

import nodework/node.{Node}
import nodework/vector.{Vector}

pub fn update_offset__from_origin__test() {
  Node(
    Vector(0, 0),
    Vector(10, 10),
    id: "foo",
    inputs: [],
    output: node.new_output("foo"),
    name: "foo",
  )
  |> node.update_offset(Vector(5, 5))
  |> should.equal(Node(
    Vector(0, 0),
    Vector(5, 5),
    id: "foo",
    inputs: [],
    output: node.new_output("foo"),
    name: "foo",
  ))
}

pub fn update_offset__from_negative__test() {
  Node(
    Vector(-10, -10),
    Vector(9999, 9999),
    id: "boo",
    inputs: [node.new_input("boo", 0, "foo"), node.new_input("boo", 1, "bar")],
    output: node.new_output("boo"),
    name: "baz",
  )
  |> node.update_offset(Vector(10, 10))
  |> should.equal(Node(
    Vector(-10, -10),
    Vector(20, 20),
    id: "boo",
    inputs: [node.new_input("boo", 0, "foo"), node.new_input("boo", 1, "bar")],
    output: node.new_output("boo"),
    name: "baz",
  ))
}
