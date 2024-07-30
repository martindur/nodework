import nodework/math.{type Vector}


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
