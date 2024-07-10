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
import graph/conn.{type Conn, Conn}
import graph/vector.{type Vector, Vector}
import graph/viewbox.{type GraphMode, type ViewBox, Drag, Normal, ViewBox}

pub type ResizeEvent
pub type MouseUpEvent

const graph_limit = 500

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

@external(javascript, "./mouse.ffi.mjs", "mouseUpEventListener")
fn document_mouse_up_event_listener(listener: fn(MouseUpEvent) -> Nil) -> Nil

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

  document_mouse_up_event_listener(fn(_) {
    UserUnclicked
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
    connections: List(Conn),
    nodes_selected: Set(NodeId),
    window_resolution: Vector,
    viewbox: ViewBox,
    navigator: Navigator,
    mode: GraphMode,
    last_clicked_point: Vector,
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
      connections: [
      ],
      nodes_selected: set.new(),
      window_resolution: get_window_size(),
      viewbox: ViewBox(Vector(0, 0), get_window_size(), 1.0),
      navigator: Navigator(Vector(0, 0), False),
      mode: Normal,
      last_clicked_point: Vector(0, 0),
    ),
    effect.none(),
  )
}

pub opaque type Msg {
  UserAddedNode(Node)
  UserMovedMouse(Vector)
  UserClickedNode(NodeId, MouseEvent)
  UserUnclickedNode(NodeId)
  UserClickedNodeOutput(NodeId, Vector)
  UserUnclicked
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
    UserAddedNode(node) -> user_added_node(model, node)
    UserMovedMouse(point) -> user_moved_mouse(model, point)
    UserClickedNode(node_id, mouse_event) ->
      user_clicked_node(model, node_id, mouse_event)
    UserUnclickedNode(_node_id) -> user_unclicked_node(model)
    UserClickedNodeOutput(node_id, offset) ->
      user_clicked_node_output(model, node_id, offset)
    UserUnclicked ->
      user_unclicked(model)
    UserClickedGraph(mouse_event) -> user_clicked_graph(model, mouse_event)
    UserScrolled(delta_y) -> user_scrolled(model, delta_y)
    GraphClearSelection -> graph_clear_selection(model)
    GraphSetDragMode -> Model(..model, mode: Drag) |> none_effect_wrapper
    GraphSetNormalMode -> Model(..model, mode: Normal) |> none_effect_wrapper
    GraphAddNodeToSelection(node_id) ->
      graph_add_node_to_selection(model, node_id)
    GraphSetNodeAsSelection(node_id) ->
      graph_set_node_as_selection(model, node_id)
    GraphResizeViewBox(resolution) -> graph_resize_view_box(model, resolution)
  }
}

fn none_effect_wrapper(model: Model) -> #(Model, Effect(Msg)) {
  #(model, effect.none())
}

fn user_added_node(model: Model, node: Node) -> #(Model, Effect(Msg)) {
  Model(..model, nodes: list.append(model.nodes, [node]))
  |> none_effect_wrapper
}

fn user_moved_mouse(model: Model, point: Vector) -> #(Model, Effect(Msg)) {
  model.navigator
  |> navigator.update_cursor_point(
    model.viewbox |> viewbox.to_viewbox_scale(point),
  )
  |> fn(nav: Navigator) {
    Model(
      ..model,
      navigator: nav,
      nodes: nd.update_node_positions(
        model.nodes,
        model.nodes_selected,
        nav.mouse_down,
        nav.cursor_point,
      ),
      connections: conn.update_active_connection_ends(model.connections, nav.cursor_point),
      viewbox: viewbox.update_offset(
        model.viewbox,
        nav.cursor_point,
        model.last_clicked_point,
        model.mode,
        graph_limit,
      ),
    )
  }
  |> none_effect_wrapper
}

fn user_clicked_node(
  model: Model,
  node_id: NodeId,
  event: MouseEvent,
) -> #(Model, Effect(Msg)) {
  model.navigator
  |> navigator.set_navigator_mouse_down
  |> fn(nav) {
    Model(
      ..model,
      navigator: nav,
      nodes: model.nodes |> nd.update_all_node_offsets(nav.cursor_point),
    )
  }
  |> fn(m) { #(m, update_selected_nodes(event, node_id)) }
}

fn user_unclicked_node(model: Model) -> #(Model, Effect(Msg)) {
  Model(..model, navigator: Navigator(..model.navigator, mouse_down: False))
  |> none_effect_wrapper
}

fn user_clicked_node_output(model: Model, node_id: NodeId, offset: Vector) -> #(Model, Effect(Msg)) {
  let pos = nd.get_position(model.nodes, node_id) |> vector.add(offset)
  let new_conn = Conn(pos, model.navigator.cursor_point, node_id, -1, True)

  model.connections
  |> list.prepend(new_conn)
  |> fn(c) { Model(..model, connections: c) }
  |> none_effect_wrapper
}

fn user_unclicked(model: Model) -> #(Model, Effect(Msg)) {
  model.connections
  |> filter(fn(c) { c.node_1_id != -1 && c.active != True})
  |> fn(c) { Model(..model, connections: c) }
  |> none_effect_wrapper
}

fn user_clicked_graph(model: Model, event: MouseEvent) -> #(Model, Effect(Msg)) {
  model
  |> update_last_clicked_point(event)
  |> fn(m) { #(m, shift_key_check(event)) }
}

fn user_scrolled(model: Model, delta_y: Float) -> #(Model, Effect(Msg)) {
  model.viewbox
  |> viewbox.update_zoom_level(delta_y)
  |> viewbox.update_resolution(model.window_resolution)
  |> fn(vb) { Model(..model, viewbox: vb) }
  |> none_effect_wrapper
}

fn graph_clear_selection(model: Model) -> #(Model, Effect(Msg)) {
  Model(..model, nodes_selected: set.new())
  |> none_effect_wrapper
}

fn graph_add_node_to_selection(
  model: Model,
  node_id: NodeId,
) -> #(Model, Effect(Msg)) {
  Model(..model, nodes_selected: model.nodes_selected |> set.insert(node_id))
  |> none_effect_wrapper
}

fn graph_set_node_as_selection(
  model: Model,
  node_id: NodeId,
) -> #(Model, Effect(Msg)) {
  Model(..model, nodes_selected: set.new() |> set.insert(node_id))
  |> none_effect_wrapper
}

fn graph_resize_view_box(
  model: Model,
  resolution: Vector,
) -> #(Model, Effect(Msg)) {
  Model(
    ..model,
    window_resolution: resolution,
    viewbox: viewbox.update_resolution(model.viewbox, resolution),
  )
  |> none_effect_wrapper
}

fn update_last_clicked_point(model: Model, event: MouseEvent) -> Model {
  event.position
  |> viewbox.to_viewbox_space(model.viewbox, _)
  |> fn(p) { Model(..model, last_clicked_point: p) }
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

fn shift_key_check(event: MouseEvent) -> Effect(Msg) {
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

fn view_node_output(id: NodeId) -> element.Element(Msg) {
  let cx = 200
  let cy = 50

  svg.circle([
    attr("cx", int.to_string(cx)),
    attr("cy", int.to_string(cy)),
    attr("r", "8"),
    attr("fill", "currentColor"),
    attribute.class("text-gray-500"),
    event.on_mouse_down(UserClickedNodeOutput(id, Vector(cx, cy))),
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
        view_node_output(node.id),
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

fn view_connection(c: Conn) -> element.Element(Msg) {
  svg.line([attr("stroke", "blue"), attr("stroke-width", "5"), ..conn.to_attributes(c)])
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
        attr_viewbox(model.viewbox.offset, model.viewbox.resolution),
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
        svg.g(
          [],
          model.connections
          |> list.map(view_connection)
        )
        // debug_draw_offset(model.nodes),
      // debug_draw_cursor_point(model.navigator),
      // debug_draw_last_clicked_point(model)
      ],
    ),
  ])
}
