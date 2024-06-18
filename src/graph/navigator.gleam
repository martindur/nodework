import graph/vector.{type Vector}


pub type Navigator {
  Navigator(
    cursor_point: Vector,
    clicked_point: Vector,
    cursor_offset: Vector,
    mouse_down: Bool
  )
}
