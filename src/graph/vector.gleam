import gleam/int.{to_string}
import gleam/string

pub type Vector {
  Vector(x: Int, y: Int)
}

pub fn subtract(a: Vector, b: Vector) -> Vector {
  Vector(x: b.x - a.x, y: b.y - a.y)
}

pub fn add(a: Vector, b: Vector) -> Vector {
  Vector(x: a.x + b.x, y: a.y + b.y)
}

pub fn get_path(start_point: Vector, end_point: Vector) -> String {
  let halfway_diff = int.absolute_value(start_point.x - end_point.y) / 2

  string.concat([
    "M ",
    to_string(start_point.x),
    " ",
    to_string(start_point.y),
    " C ",
    to_string(start_point.x + halfway_diff),
    " ",
    to_string(start_point.y),
    ", ",
    to_string(end_point.x - halfway_diff),
    " ",
    to_string(end_point.y),
    ", ",
    to_string(end_point.x),
    " ",
    to_string(end_point.y),
  ])
}
