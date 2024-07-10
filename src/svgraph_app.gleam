import gleam/dynamic.{type DecodeError}
import gleam/float
import gleam/int
import gleam/io
import gleam/list.{filter, map}
import gleam/result
import gleam/set.{type Set}
import lustre
import lustre/attribute.{type Attribute, attribute as attr}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/element/svg
import lustre/event

import graph/navigator.{type Navigator, Navigator}
import graph/node.{type Node, type NodeId, Node} as nd
import graph/vector.{type Vector, Vector}
import graph/viewbox

pub type ResizeEvent

type GraphMode {
  Normal
  Drag
}

const graph_limit = 500

const scroll_factor = 0.1

const limit_zoom_in = 0.5

const limit_zoom_out = 3.0

@external(javascript, "./resize.ffi.mjs", "windowSize")
fn window_size() -> #(Int, Int)

fn get_window_size() -> Vector {
  window_size()
  |> fn(z) {
    let #(x, y) = z
    Vector(x: x, y: y)
  }
}

@external(javascript, "./resize.ffi.mjs", "documentResizeEventListener")
fn document_resize_event_listener(listener: fn(ResizeEvent) -> Nil) -> Nil

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(send_to_runtime) = lustre.start(app, "#app", Nil)

  // A few notes might be helpful here.
  // This is how we can communicate with document/window
  // In this case, we parse window size as a Resolution,
  // which is piped to a GraphResize Msg.

  // We then use the dispatch to handle it as a msg to update
  // and finally send it to the runtime, which returns Nil.
  // And that's our handler hooked on the listener
  document_resize_event_listener(fn(_) {
    get_window_size()
    |> GraphResizeViewBox
    |> lustre.dispatch
    |> send_to_runtime
  })

  Nil
}

type MouseEvent {
  MouseEvent(position: Vector, shift_key_active: Bool)
}

type Model {
  Model(
    nodes: List(Node),
    nodes_selected: Set(NodeId),
    window_resolution: Vector,
    active_resolution: Vector,
    offset: Vector,
    navigator: Navigator,
    mode: GraphMode,
    last_clicked_point: Vector,
    zoom_level: Float,
  )
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    Model(
      nodes: [
        Node(
          position: Vector(0, 0),
          offset: Vector(0, 0),
          id: 0,
          inputs: ["foo", "bar", "baz"],
          name: "Rect",
        ),
        Node(
          position: Vector(300, 300),
          offset: Vector(0, 0),
          id: 1,
          inputs: ["bob"],
          name: "Circle",
        ),
      ],
      nodes_selected: set.new(),
      window_resolution: get_window_size(),
      active_resolution: get_window_size(),
      offset: Vector(0, 0),
      navigator: Navigator(Vector(0, 0), False),
      mode: Normal,
      last_clicked_point: Vector(0, 0),
      zoom_level: 1.0,
    ),
    effect.none(),
  )
}

pub opaque type Msg {
  UserAddedNode(Node)
  UserMovedMouse(Vector)
  UserClickedNode(NodeId, MouseEvent)
  UserUnclickedNode(NodeId)
  UserClickedGraph(MouseEvent)
  UserScrolled(Float)
  GraphClearSelection
  GraphSetDragMode
  GraphSetNormalMode
  GraphAddNodeToSelection(NodeId)
  GraphSetNodeAsSelection(NodeId)
  GraphResizeViewBox(Vector)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedNode(node) -> #(
      Model(..model, nodes: list.append(model.nodes, [node])),
      effect.none(),
    )
    UserMovedMouse(point) -> user_moved_mouse(model, point)
    UserClickedNode(node_id, mouse_event) -> #(
      model
        |> set_navigator_mouse_down
        |> update_all_node_offsets,
      update_selected_nodes(mouse_event, node_id),
    )
    UserUnclickedNode(_node_id) -> #(
      Model(..model, navigator: Navigator(..model.navigator, mouse_down: False)),
      effect.none(),
    )
    UserClickedGraph(mouse_event) -> #(
      model |> update_last_clicked_point(mouse_event),
      user_clicked_graph(mouse_event),
    )
    UserScrolled(delta_y) -> user_scrolled(model, delta_y)
    GraphClearSelection -> #(
      Model(..model, nodes_selected: set.new()),
      effect.none(),
    )
    GraphSetDragMode -> #(Model(..model, mode: Drag), effect.none())
    GraphSetNormalMode -> #(Model(..model, mode: Normal), effect.none())
    GraphAddNodeToSelection(node_id) -> #(
      Model(
        ..model,
        nodes_selected: model.nodes_selected |> set.insert(node_id),
      ),
      effect.none(),
    )
    GraphSetNodeAsSelection(node_id) -> #(
      Model(..model, nodes_selected: set.new() |> set.insert(node_id)),
      effect.none(),
    )
    GraphResizeViewBox(resolution) -> graph_resize_view_box(model, resolution)
  }
}

fn effect_none_wrap(model: Model) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

fn user_moved_mouse(model: Model, point: Vector) -> #(Model, Effect(Msg)) {
  model.navigator
  |> navigator.update_cursor_point(point, model.zoom_level)
  |> fn(nav: Navigator) {
    let offset = case model.mode {
      Normal -> model.offset
      Drag -> viewbox.update_offset(nav.cursor_point, model.last_clicked_point, graph_limit)
    }

    let nodes = nd.update_node_positions(model.nodes, model.nodes_selected, nav.mouse_down, nav.cursor_point)

    Model(..model, navigator: nav, offset: offset, nodes: nodes)
  }
  |> effect_none_wrap
}

fn user_scrolled(model: Model, delta_y: Float) -> #(Model, Effect(Msg)) {
  model.zoom_level
  |> viewbox.update_zoom_level(
    delta_y,
    scroll_factor,
    limit_zoom_out,
    limit_zoom_in,
  )
  |> fn(zoom_level) {
    Model(
      ..model,
      zoom_level: zoom_level,
      active_resolution: vector.scalar(model.window_resolution, zoom_level),
    )
  }
  |> effect_none_wrap
}

fn graph_resize_view_box(
  model: Model,
  resolution: Vector,
) -> #(Model, Effect(Msg)) {
  Model(
    ..model,
    window_resolution: resolution,
    active_resolution: vector.scalar(resolution, model.zoom_level),
  )
  |> effect_none_wrap
}

fn set_navigator_mouse_down(model: Model) -> Model {
  Navigator(..model.navigator, mouse_down: True)
  |> fn(nav) { Model(..model, navigator: nav) }
}

fn update_last_clicked_point(model: Model, event: MouseEvent) -> Model {
  event.position
  |> vector.scalar(model.zoom_level)
  |> vector.add(model.offset)
  |> fn(p) { Model(..model, last_clicked_point: p) }
}

fn update_all_node_offsets(model: Model) -> Model {
  model.nodes
  |> map(nd.update_offset(_, model.navigator.cursor_point))
  |> fn(x) { Model(..model, nodes: x) }
}

fn update_selected_nodes(event: MouseEvent, node_id: NodeId) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case event.shift_key_active {
      True -> GraphAddNodeToSelection(node_id)
      False -> GraphSetNodeAsSelection(node_id)
    }
    |> dispatch
  })
}

fn user_clicked_graph(event: MouseEvent) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case event.shift_key_active {
      True -> GraphSetDragMode
      False -> GraphClearSelection
    }
    |> dispatch
  })
}

fn mouse_event_decoder(e) -> Result(MouseEvent, List(DecodeError)) {
  event.stop_propagation(e)

  use shift_key <- result.try(dynamic.field("shiftKey", dynamic.bool)(e))
  use position <- result.try(event.mouse_position(e))

  Ok(MouseEvent(
    position: Vector(float.round(position.0), float.round(position.1)),
    shift_key_active: shift_key,
  ))
}

pub fn on_mouse_move(msg: msg) -> Attribute(msg) {
  use _ <- event.on("mousemove")
  Ok(msg)
}

fn translate(x: Int, y: Int) -> String {
  let x_string = int.to_string(x)
  let y_string = int.to_string(y)

  "translate(" <> x_string <> "," <> y_string <> ")"
}

fn attr_viewbox(offset: Vector, resolution: Vector) -> Attribute(Msg) {
  [offset.x, offset.y, resolution.x, resolution.y]
  |> list.map(int.to_string)
  |> list.reduce(fn(a, b) { a <> " " <> b })
  |> fn(result) {
    case result {
      Ok(res) -> attr("viewBox", res)
      Error(_) -> attr("viewBox", "0 0 100 100")
    }
  }
}

fn debug_draw_offset(nodes: List(Node)) -> element.Element(Msg) {
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

fn debug_draw_cursor_point(navigator: Navigator) -> element.Element(Msg) {
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

fn debug_draw_last_clicked_point(model: Model) -> element.Element(Msg) {
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

fn view_node_input(input: String, index: Int) -> element.Element(Msg) {
  svg.g(
    [
      attr(
        "transform",
        "translate(0, " <> { 50 + index * 30 } |> int.to_string() <> ")",
      ),
    ],
    [
      svg.circle([
        attr("cx", "0"),
        attr("cy", "0"),
        attr("r", "8"),
        attr("fill", "currentColor"),
        attribute.class("text-gray-500"),
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
        input,
      ),
    ],
  )
}

fn view_node_output() -> element.Element(Msg) {
  svg.circle([
    attr("cx", "200"),
    attr("cy", "50"),
    attr("r", "8"),
    attr("fill", "currentColor"),
    attribute.class("text-gray-500"),
  ])
}

// TODO: Dragging multiple nodes requires holding down shift.
// Dragging should be done with "mousedown(no shift)" |> "mousemove"
// Find a way to make this work. The main problem is that when you do "mousedown", it unselects other nodes.
fn view_node(node: Node, selection: Set(NodeId)) -> element.Element(Msg) {
  let node_selected_class = case set.contains(selection, node.id) {
    True -> attribute.class("text-gray-300 stroke-gray-400")
    False -> attribute.class("text-gray-300 stroke-gray-300")
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedNode(node.id, decoded_event))
  }

  svg.g(
    [
      attribute.id("node-" <> int.to_string(node.id)),
      attr("transform", translate(node.position.x, node.position.y)),
      attribute.class("select-none"),
    ],
    list.concat([
      [
        svg.rect([
          attribute.id(int.to_string(node.id)),
          attr("width", "200"),
          attr("height", "150"),
          attr("rx", "25"),
          attr("ry", "25"),
          attr("fill", "currentColor"),
          attr("stroke", "currentColor"),
          attr("stroke-width", "2"),
          node_selected_class,
          event.on("mousedown", mousedown),
          event.on_mouse_up(UserUnclickedNode(node.id)),
        ]),
        svg.text(
          [
            attr("x", "20"),
            attr("y", "24"),
            attr("font-size", "16"),
            attr("fill", "currentColor"),
            attribute.class("text-gray-900"),
          ],
          node.name,
        ),
        view_node_output(),
      ],
      list.index_map(node.inputs, fn(input, i) { view_node_input(input, i) }),
    ]),
  )
}

fn view_grid_canvas(width: Int, height: Int) -> element.Element(Msg) {
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

fn view_grid() -> element.Element(Msg) {
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

fn view(model: Model) -> element.Element(Msg) {
  let user_moved_mouse = fn(e) -> Result(Msg, List(DecodeError)) {
    result.try(event.mouse_position(e), fn(pos) {
      Ok(UserMovedMouse(Vector(x: float.round(pos.0), y: float.round(pos.1))))
    })
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedGraph(decoded_event))
  }

  let wheel = fn(e) -> Result(Msg, List(DecodeError)) {
    use delta_y <- result.try(dynamic.field("deltaY", dynamic.float)(e))

    Ok(UserScrolled(delta_y))
  }

  html.div([], [
    html.p([attribute.class("absolute right-2 top-2 select-none")], [
      case model.mode {
        Normal -> element.text("NORMAL")
        Drag -> element.text("DRAG")
      },
    ]),
    svg.svg(
      [
        attribute.id("graph"),
        attr_viewbox(model.offset, model.active_resolution),
        attr("contentEditable", "true"),
        event.on("mousemove", user_moved_mouse),
        event.on("mousedown", mousedown),
        event.on_mouse_up(GraphSetNormalMode),
        event.on("wheel", wheel),
      ],
      [
        view_grid(),
        view_grid_canvas(500, 500),
        svg.g(
          [],
          model.nodes
            |> list.map(fn(node: Node) { view_node(node, model.nodes_selected) }),
        ),
        // debug_draw_offset(model.nodes),
      // debug_draw_cursor_point(model.navigator),
      // debug_draw_last_clicked_point(model)
      ],
    ),
  ])
}
