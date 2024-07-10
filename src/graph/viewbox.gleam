import gleam/float
import graph/vector.{type Vector}

const scroll_factor = 0.1

const limit_zoom_in = 0.5

const limit_zoom_out = 3.0

pub type GraphMode {
  Normal
  Drag
}

pub type ViewBox {
  ViewBox(offset: Vector, resolution: Vector, zoom_level: Float)
}

pub fn update_offset(
  vb: ViewBox,
  point: Vector,
  offset: Vector,
  mode: GraphMode,
  limit: Int,
) -> ViewBox {
  case mode {
    Normal -> vb.offset
    Drag ->
      point
      |> vector.subtract(offset, _)
      |> vector.inverse
      |> vector.bounded_vector(limit)
  }
  |> fn(offset) { ViewBox(..vb, offset: offset) }
}

pub fn update_resolution(vb: ViewBox, resolution: Vector) -> ViewBox {
  vb.zoom_level
  |> vector.scalar(resolution, _)
  |> fn(res) { ViewBox(..vb, resolution: res) }
}

pub fn update_zoom_level(vb: ViewBox, delta_y: Float) -> ViewBox {
  delta_y
  |> fn(d) {
    case d >. 0.0 {
      True -> 1.0 *. scroll_factor
      False -> -1.0 *. scroll_factor
    }
  }
  |> float.add(vb.zoom_level)
  |> float.min(limit_zoom_out)
  |> float.max(limit_zoom_in)
  |> fn(zoom) { ViewBox(..vb, zoom_level: zoom) }
}
