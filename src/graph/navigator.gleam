import graph/vector.{type Vector}

pub type Navigator {
  Navigator(
    cursor_point: Vector,
    clicked_point: Vector,
    cursor_offset: Vector,
    mouse_down: Bool,
  )
}

// I don't know if the expression here is very clear.
// Mainly that we initially calculate the difference, and add that to the initial clicked point
pub fn calc_position(navigator: Navigator, offset: Vector) -> Vector {
  navigator.clicked_point
  |> vector.subtract(navigator.cursor_point)
  |> vector.add(navigator.clicked_point)
  |> vector.subtract(offset, _)
}
