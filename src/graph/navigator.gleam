import graph/vector.{type Vector, Vector}

pub type Navigator {
  Navigator(cursor_point: Vector, mouse_down: Bool)
}

pub fn calc_position(navigator: Navigator, offset: Vector) -> Vector {
  navigator.cursor_point
  |> vector.subtract(offset, _)
}

pub fn update_cursor_point(nav: Navigator, point: Vector, scalar: Float) -> Navigator {
  point
  |> vector.scalar(scalar)
  |> fn(p) { Navigator(..nav, cursor_point: p) }
}
