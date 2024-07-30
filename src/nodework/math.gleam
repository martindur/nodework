import gleam/float.{round}
import gleam/int.{to_float}

pub type Vector {
  Vector(x: Int, y: Int)
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

pub fn map_vector(vec: Vector, func: fn(Int) -> Int) -> Vector {
  Vector(x: func(vec.x), y: func(vec.y))
}
