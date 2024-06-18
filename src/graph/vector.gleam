import gleam/int.{to_string}
import gleam/string

pub type Vector {
  Vector(x: Int, y: Int)
}

pub fn subtract(a: Vector, b: Vector) -> Vector {
  Vector(x: a.x - b.x, y: a.y - b.y)
}

pub fn add(a: Vector, b: Vector) -> Vector {
  Vector(x: a.x + b.x, y: a.y + b.y)
}

pub fn translate_node(
  start_point: Vector,
  current_point: Vector,
  offset: Vector,
) -> Vector {
  let diff_x = current_point.x - start_point.x
  let diff_y = current_point.y - start_point.y

  Vector(
    x: start_point.x + diff_x - offset.x,
    y: start_point.y + diff_y - offset.y,
  )

  Vector(x: current_point.x - offset.x, y: current_point.y - offset.y)
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
