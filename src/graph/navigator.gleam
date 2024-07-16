import graph/vector.{type Vector, Vector}

pub type Navigator {
  Navigator(cursor_point: Vector, mouse_down: Bool)
}

pub fn calc_position(navigator: Navigator, offset: Vector) -> Vector {
  navigator.cursor_point
  |> vector.subtract(offset, _)
}

pub fn set_navigator_mouse_down(nav: Navigator) -> Navigator {
  Navigator(..nav, mouse_down: True)
}
