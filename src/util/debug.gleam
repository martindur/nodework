import gleam/int
import gleam/list.{map}
import lustre/element
import lustre/attribute.{attribute as attr}
import lustre/element/svg
import nodework/node.{type Node}
import nodework/vector.{type Vector}
import nodework/navigator.{type Navigator}
import nodework/model.{type Model}


pub fn debug_draw_offset(nodes: List(Node)) -> element.Element(msg) {
  svg.g(
    [],
    nodes
      |> map(fn(node) {
        [
          attr("x1", int.to_string(node.position.x)),
          attr("y1", int.to_string(node.position.y)),
          attr("x2", int.to_string(node.position.x + node.offset.x)),
          attr("y2", int.to_string(node.position.y + node.offset.y)),
          attr("stroke", "red"),
        ]
        |> svg.line()
      }),
  )
}

pub fn debug_draw_cursor_point(navigator: Navigator) -> element.Element(msg) {
  navigator.cursor_point
  |> fn(p: Vector) {
    [
      attr("r", "2"),
      attr("color", "red"),
      attr("cx", p.x |> int.to_string),
      attr("cy", p.y |> int.to_string),
    ]
  }
  |> svg.circle()
}

pub fn debug_draw_last_clicked_point(model: Model) -> element.Element(msg) {
  model.last_clicked_point
  |> fn(p: Vector) {
    [
      attr("r", "2"),
      attr("color", "red"),
      attr("cx", p.x |> int.to_string),
      attr("cy", p.y |> int.to_string),
    ]
  }
  |> svg.circle()
}
