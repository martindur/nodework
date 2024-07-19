import gleam/float.{round}
import gleam/int.{to_float, to_string}
import gleam/string

pub type Vector {
  Vector(x: Int, y: Int)
}

pub type Transform {
  Translate
  Scale
  Rotate
}

pub fn subtract(a: Vector, b: Vector) -> Vector {
  Vector(x: b.x - a.x, y: b.y - a.y)
}

pub fn mult(a: Vector, b: Vector) -> Vector {
  Vector(x: b.x * a.x, y: b.y * a.y)
}

pub fn scalar(vec: Vector, b: Float) -> Vector {
  vec
  |> map_vector(fn(val) {
    val
    |> to_float
    |> fn(x) { x *. b }
    |> round()
  })
}

pub fn divide(vec: Vector, b: Float) -> Vector {
  vec
  |> map_vector(fn(val) {
    val
    |> to_float
    |> fn(x) { x /. b }
    |> round()
  })
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

pub fn to_html(vec: Vector, t: Transform) -> String {
  case t {
    Translate -> "translate("
    Scale -> "scale("
    Rotate -> "rotate("
  }
  |> fn(t) { t <> int.to_string(vec.x) <> "," <> int.to_string(vec.y) <> ")" }
}
