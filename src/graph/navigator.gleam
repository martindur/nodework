import graph/vector.{type Vector}

pub type Navigator {
  Navigator(
    cursor_point: Vector,
    clicked_point: Vector,
    cursor_offset: Vector,
    mouse_down: Bool,
  )
}

pub fn calc_position(navigator: Navigator, offset: Vector) -> Vector {
  navigator.clicked_point
  |> vector.subtract(navigator.cursor_point)
  |> vector.add(navigator.clicked_point)
  |> vector.subtract(offset, _)

  // let diff_x = current_point.x - start_point.x
  // let diff_y = current_point.y - start_point.y

  // Vector(
  //   x: start_point.x + diff_x - offset.x,
  //   y: start_point.y + diff_y - offset.y,
  // )
}
