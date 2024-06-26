import graph/vector.{type Vector, Vector}

pub type Navigator {
  Navigator(cursor_point: Vector, mouse_down: Bool)
}

pub fn calc_position(navigator: Navigator, offset: Vector) -> Vector {
  navigator.cursor_point
  |> vector.subtract(offset, _)
}

pub fn inverse(p: Vector) -> Vector {
  Vector(p.x * -1, p.y * -1)
}
