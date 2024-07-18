import gleeunit/should
import nodework/navigator.{Navigator}
import nodework/vector.{Vector}

pub fn calc_position__test() {
  let current_cursor_position = Vector(50, 50)
  let offset_from_initial_clicked_point = Vector(10, 10)

  Navigator(current_cursor_position, False)
  |> navigator.calc_position(offset_from_initial_clicked_point)
  |> should.equal(Vector(40, 40))
}

pub fn calc_position__from_origin__test() {
  let current_cursor_position = Vector(50, 50)
  let offset_from_initial_clicked_point = Vector(0, 0)

  Navigator(current_cursor_position, False)
  |> navigator.calc_position(offset_from_initial_clicked_point)
  |> should.equal(Vector(50, 50))
}

/// This is just to drive home the point that
pub fn calc_position__from_origin_alt__test() {
  let current_cursor_position = Vector(50, 50)
  let offset_from_initial_clicked_point = Vector(0, 0)

  Navigator(current_cursor_position, False)
  |> navigator.calc_position(offset_from_initial_clicked_point)
  |> should.equal(Vector(50, 50))
}
