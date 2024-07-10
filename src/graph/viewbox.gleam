import gleam/float
import graph/vector.{type Vector}

pub fn update_zoom_level(
  zoom_level: Float,
  delta_y: Float,
  factor: Float,
  limit_zoom_out: Float,
  limit_zoom_in: Float,
) -> Float {
  delta_y
  |> fn(d) {
    case d >. 0.0 {
      True -> 1.0 *. factor
      False -> -1.0 *. factor
    }
  }
  |> float.add(zoom_level)
  |> float.min(limit_zoom_out)
  |> float.max(limit_zoom_in)
}

pub fn update_offset(point: Vector, offset: Vector, limit: Int) -> Vector {
  point
  |> vector.subtract(offset, _)
  |> vector.inverse
  |> vector.bounded_vector(limit)
}
