//// The viewbox module contains functions for calculating a viewbox in an svg element. Such as offset and resolution.
//// Furthermore it manages a zoom level for drawing elements at a scaled resolution

import gleam/float
import gleam/io
import nodework/vector.{type Vector}

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

/// Scales a vector, with respect to the zoom level of a viewbox
pub fn to_viewbox_scale(vb: ViewBox, p: Vector) -> Vector {
  p
  |> vector.scalar(vb.zoom_level)
}

pub fn to_viewbox_translate(vb: ViewBox, p: Vector) -> Vector {
  p
  |> vector.add(vb.offset)
}

/// Transforms a vector into the space of a viewbox
pub fn to_viewbox_space(vb: ViewBox, p: Vector) -> Vector {
  p
  |> vector.scalar(vb.zoom_level)
  |> vector.add(vb.offset)
}

pub fn from_viewbox_scale(vb: ViewBox, p: Vector) -> Vector {
  p
  |> vector.divide(vb.zoom_level)
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
