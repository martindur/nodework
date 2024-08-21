import gleam/float.{round}
import gleam/int.{to_float}

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

pub fn vec_to_html(vec: Vector, t: Transform) -> String {
  case t {
    Translate -> "translate("
    Scale -> "scale("
    Rotate -> "rotate("
  }
  |> fn(t) { t <> int.to_string(vec.x) <> "," <> int.to_string(vec.y) <> ")" }
}
