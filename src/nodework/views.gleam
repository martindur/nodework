import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/float
import gleam/int
import gleam/list.{map, reduce, filter}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string

import lustre/attribute.{type Attribute, attribute as attr}
import lustre/element
import lustre/element/html
import lustre/element/svg
import lustre/event

import nodework/decoder.{mouse_event_decoder}
import nodework/draw/content
import nodework/draw/viewbox.{type ViewBox, ViewBox}
import nodework/lib.{type LibraryMenu}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, type Msg, DragMode, Model, NormalMode, UserClickedGraph,
  UserMovedMouse, GraphSetMode
}
import nodework/conn.{type Conn, Conn}
import nodework/node.{type UINode, UINode, type UINodeInput, type UINodeID}

fn view_menu_item(
  item: #(String, String),
  spawn_func: fn(Dynamic) -> Result(msg, List(DecodeError)),
) -> element.Element(msg) {
  let #(category, key) = item
  let text = string.capitalise(key)
  html.button(
    [
      attr("data-identifier", category <> "." <> key),
      attribute.class("hover:bg-gray-300"),
      event.on("click", spawn_func),
    ],
    [element.text(text)],
  )
}

pub fn view_menu(
  menu: LibraryMenu,
  spawn_func: fn(Dynamic) -> Result(msg, List(DecodeError)),
) -> element.Element(msg) {
  let pos =
    "translate("
    <> int.to_string(menu.position.x)
    <> "px, "
    <> int.to_string(menu.position.y)
    <> "px)"

  html.div(
    case menu.visible {
      True -> [
        attribute.class(
          "absolute top-0 left-0 w-[100px] h-[300px] bg-gray-200 rounded shadow",
        ),
        attribute.style([#("transform", pos)]),
      ]
      False -> [attribute.class("hidden")]
    },
    [
      html.div(
        [attribute.class("flex flex-col p-2 gap-1")],
        menu.nodes
          |> list.map(fn(item) { view_menu_item(item, spawn_func) }),
      ),
    ],
  )
}

fn view_grid_canvas(width: Int, height: Int) -> element.Element(msg) {
  let w = int.to_string(width) <> "%"
  let h = int.to_string(height) <> "%"

  let x = "-" <> int.to_string(width / 2) <> "%"
  let y = "-" <> int.to_string(height / 2) <> "%"

  svg.rect([
    attr("x", x),
    attr("y", y),
    attr("width", w),
    attr("height", h),
    attr("fill", "url(#grid)"),
  ])
}

fn view_grid() -> element.Element(msg) {
  svg.defs([], [
    svg.pattern(
      [
        attribute.id("smallGrid"),
        attr("width", "8"),
        attr("height", "8"),
        attr("patternUnits", "userSpaceOnUse"),
      ],
      [
        svg.path([
          attr("d", "M 8 0 L 0 0 0 8"),
          attr("fill", "none"),
          attr("stroke", "gray"),
          attr("stroke-width", "0.5"),
        ]),
      ],
    ),
    svg.pattern(
      [
        attribute.id("grid"),
        attr("width", "80"),
        attr("height", "80"),
        attr("patternUnits", "userSpaceOnUse"),
      ],
      [
        svg.rect([
          attr("width", "80"),
          attr("height", "80"),
          attr("fill", "url(#smallGrid)"),
        ]),
        svg.path([
          attr("d", "M 80 0 L 0 0 0 80"),
          attr("fill", "none"),
          attr("stroke", "gray"),
          attr("stroke-width", "1"),
        ]),
      ],
    ),
  ])
}

fn attr_viewbox(offset: Vector, resolution: Vector) -> Attribute(msg) {
  [offset.x, offset.y, resolution.x, resolution.y]
  |> map(int.to_string)
  |> reduce(fn(a, b) { a <> " " <> b })
  |> fn(result) {
    case result {
      Ok(res) -> attr("viewBox", res)
      Error(_) -> attr("viewBox", "0 0 100 100")
    }
  }
}

pub fn view_canvas(
  viewbox: ViewBox,
  nodes: Dict(UINodeID, UINode),
  selection: Set(UINodeID),
  connections: List(Conn),
) -> element.Element(Msg) {
  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedGraph(event))
  }

  let mousemove = fn(e) -> Result(Msg, List(DecodeError)) {
    result.try(event.mouse_position(e), fn(pos) {
      Ok(UserMovedMouse(Vector(x: float.round(pos.0), y: float.round(pos.1))))
    })
  }

  svg.svg(
    [
      attribute.id("graph"),
      attr("contentEditable", "true"),
      attr_viewbox(viewbox.offset, viewbox.resolution),
      event.on("mousedown", mousedown),
      event.on("mousemove", mousemove),
      event.on_mouse_up(GraphSetMode(NormalMode)),
    ],
    [
      view_grid(),
      view_grid_canvas(500, 500),
      svg.g(
        [],
        connections
          |> map(content.view_connection),
      ),
      svg.g(
        [],
        nodes
          |> dict.to_list
          |> map(pair.second)
          |> map(fn(node: UINode) { content.view_node(node, selection) }),
      ),
    ],
  )
}
