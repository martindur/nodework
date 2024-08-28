import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/float
import gleam/int
import gleam/list.{map, reduce}
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string

import lustre/attribute.{type Attribute, attribute as attr}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event

import nodework/conn.{type Conn, Conn}
import nodework/decoder.{mouse_event_decoder}
import nodework/views/util.{translate, output_to_element}
import nodework/draw/viewbox.{type ViewBox, ViewBox}
import nodework/lib.{type LibraryMenu}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Msg, type Model, GraphSetMode, NormalMode,
  UserClickedGraph, UserClickedNode, UserUnclickedNode, UserHoverNodeInput, UserUnhoverNodeInputs, UserClickedNodeOutput, UserHoverNodeOutput, UserUnhoverNodeOutputs, UserMovedMouse, UserClickedConn, UserScrolled
}
import nodework/node.{type UINode, type UINodeID, type UINodeInput, type UINodeOutput, UINode}

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

pub fn view_graph(
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

  let wheel = fn(e) -> Result(Msg, List(DecodeError)) {
    use delta_y <- result.try(dynamic.field("deltaY", dynamic.float)(e))

    Ok(UserScrolled(delta_y))
  }

  svg.svg(
    [
      attribute.id("graph"),
      attr("contentEditable", "true"),
      attr_viewbox(viewbox.offset, viewbox.resolution),
      event.on("mousedown", mousedown),
      event.on("mousemove", mousemove),
      event.on_mouse_up(GraphSetMode(NormalMode)),
      event.on("wheel", wheel)
    ],
    [
      view_grid(),
      view_grid_canvas(500, 500),
      svg.g(
        [],
        connections
          |> map(view_connection),
      ),
      svg.g(
        [],
        nodes
          |> dict.to_list
          |> map(pair.second)
          |> map(fn(node: UINode) { view_node(node, selection) }),
      ),
    ],
  )
}

pub fn view_node(n: UINode, selection: Set(UINodeID)) -> Element(Msg) {
  let node_selected_class = case set.contains(selection, n.id) {
    True -> attribute.class("text-gray-300 stroke-gray-400")
    False -> attribute.class("text-gray-300 stroke-gray-300")
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedNode(n.id, decoded_event))
  }

  svg.g(
    [
      attribute.id("g-" <> n.id),
      attr("transform", translate(n.position.x, n.position.y)),
      attribute.class("select-none"),
    ],
    list.concat([
      [
        svg.rect([
          attribute.id(n.id),
          attr("width", "200"),
          attr("height", "150"),
          attr("rx", "25"),
          attr("ry", "25"),
          attr("fill", "currentColor"),
          attr("stroke", "currentColor"),
          attr("stroke-width", "2"),
          node_selected_class,
          event.on("mousedown", mousedown),
          event.on_mouse_up(UserUnclickedNode),
        ]),
        svg.text(
          [
            attr("x", "20"),
            attr("y", "24"),
            attr("font-size", "16"),
            attr("fill", "currentColor"),
            attribute.class("text-gray-900"),
          ],
          n.label,
        ),
        view_node_output(n.output, n.id),
      ],
      list.map(n.inputs, fn(input) { view_node_input(input) }),
    ]),
  )
}

fn view_node_input(input: UINodeInput) -> element.Element(Msg) {
  svg.g(
    [attr("transform", input.position |> math.vec_to_html(math.Translate))],
    [
      svg.circle([
        attr("cx", "0"),
        attr("cy", "0"),
        attr("r", "10"),
        attr("fill", "currentColor"),
        attr("stroke", "black"),
        case input.hovered {
          True -> attr("stroke-width", "3")
          False -> attr("stroke-width", "0")
        },
        attribute.class("text-gray-500"),
        attribute.id(input.id),
        event.on_mouse_enter(UserHoverNodeInput(input.id)),
        event.on_mouse_leave(UserUnhoverNodeInputs),
      ]),
      svg.text(
        [
          attr("x", "16"),
          attr("y", "0"),
          attr("font-size", "16"),
          attr("dominant-baseline", "middle"),
          attr("fill", "currentColor"),
          attribute.class("text-gray-900"),
        ],
        input.label,
      ),
    ],
  )
}

fn view_node_output(
  output: UINodeOutput,
  node_id: UINodeID,
) -> element.Element(Msg) {
  // TODO: Consider having an output node type, as this becomes quite hidden. It's much easier at the moment though!
  case node_id == "node.output" {
    False -> {
      svg.g(
        [attr("transform", output.position |> math.vec_to_html(math.Translate))],
        [
          svg.circle([
            attr("cx", "0"),
            attr("cy", "0"),
            attr("r", "10"),
            attr("fill", "currentColor"),
            attr("stroke", "black"),
            case output.hovered {
              True -> attr("stroke-width", "3")
              False -> attr("stroke-width", "0")
            },
            attribute.class("text-gray-500"),
            event.on_mouse_down(UserClickedNodeOutput(node_id, output.position)),
            event.on_mouse_enter(UserHoverNodeOutput(output.id)),
            event.on_mouse_leave(UserUnhoverNodeOutputs),
          ]),
        ],
      )
    }
    True -> element.none()
  }
}

pub fn view_connection(c: Conn) -> element.Element(Msg) {
  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedConn(c.id, decoded_event))
  }

  svg.line([
    case c.dragged {
      True -> attribute.class("text-gray-500")
      False -> attribute.class("text-gray-500 hover:text-indigo-500")
    },
    attr("stroke", "currentColor"),
    attr("stroke-width", "10"),
    attr("stroke-linecap", "round"),
    attr("stroke-dasharray", "12,12"),
    event.on("mousedown", mousedown),
    ..conn.to_attributes(c)
  ])
}

pub fn view_output_canvas(model: Model) -> element.Element(Msg) {
  html.div(
    [
      attribute.class(
        "w-80 h-80 absolute bottom-2 right-2 rounded border border-gray-300 bg-white flex items-center justify-center",
      ),
      output_to_element(model.output),
    ],
    [],
  )
}
