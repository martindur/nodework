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

pub fn map_vector(vec: Vector, f: fn(Int) -> Int) -> Vector {
  Vector(x: f(vec.x), y: f(vec.y))
}

pub fn bounded_vector(vec: Vector, bound: Int) -> Vector {
  vec
  |> map_vector(fn(val) { int.min(val, bound) |> int.max({ bound * -1 }) })
}

pub fn inverse(p: Vector) -> Vector {
  Vector(p.x * -1, p.y * -1)
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
