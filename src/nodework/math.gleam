import gleam/float.{round}
import gleam/string
import gleam/int.{to_float, to_string}

pub type Vector {
  Vector(x: Int, y: Int)
}

pub type Transform {
  Translate
  Scale
  Rotate
}

pub fn vector_scalar(vec: Vector, scalar: Float) -> Vector {
  vec
  |> map_vector(fn(val) {
    val
    |> to_float
    |> fn(component) { component *. scalar }
    |> round
  })
}

pub fn vector_divide(vec: Vector, divisor: Float) -> Vector {
  vec
  |> map_vector(fn(val) {
    val
    |> to_float
    |> fn(x) { x /. divisor }
    |> round()
  })
}

pub fn vector_add(a: Vector, b: Vector) -> Vector {
  Vector(x: a.x + b.x, y: a.y + b.y)
}

pub fn vector_subtract(a: Vector, b: Vector) -> Vector {
  Vector(x: b.x - a.x, y: b.y - a.y)
}

pub fn map_vector(vec: Vector, func: fn(Int) -> Int) -> Vector {
  Vector(x: func(vec.x), y: func(vec.y))
}

pub fn vector_inverse(vec: Vector) -> Vector {
  Vector(vec.x * -1, vec.y * -1)
}

pub fn bounded_vector(vec: Vector, bound: Int) -> Vector {
  vec
  |> map_vector(fn(val) { int.min(val, bound) |> int.max({ bound * -1 }) })
}

pub fn vector_to_path(start_point: Vector, end_point: Vector) -> String {
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

pub fn vec_to_html(vec: Vector, t: Transform) -> String {
  case t {
    Translate -> "translate("
    Scale -> "scale("
    Rotate -> "rotate("
  }
  |> fn(t) { t <> int.to_string(vec.x) <> "," <> int.to_string(vec.y) <> ")" }
}
