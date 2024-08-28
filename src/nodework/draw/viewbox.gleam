import gleam/float
import nodework/math.{type Vector}

const scroll_factor = 0.1
const limit_zoom_in = 0.5
const limit_zoom_out = 3.0

pub type ViewBox {
  ViewBox(offset: Vector, resolution: Vector, zoom_level: Float)
}

pub fn update_resolution(vb: ViewBox, resolution: Vector) -> ViewBox {
  vb.zoom_level
  |> math.vector_scalar(resolution, _)
  |> fn(res) { ViewBox(..vb, resolution: res) }
}

pub fn unscale(vb: ViewBox, vec: Vector) -> Vector {
  vec
  |> math.vector_divide(vb.zoom_level)
}

pub fn scale(vb: ViewBox, vec: Vector) -> Vector {
  vec
  |> math.vector_scalar(vb.zoom_level)
}

pub fn translate(vb: ViewBox, vec: Vector) -> Vector {
  vec
  |> math.vector_add(vb.offset)
}

pub fn transform(vb: ViewBox, vec: Vector) -> Vector {
  vec
  |> math.vector_scalar(vb.zoom_level)
  |> math.vector_add(vb.offset)
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
