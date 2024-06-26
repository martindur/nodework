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

pub type ResizeEvent

type GraphMode {
  Normal
  Drag
}

@external(javascript, "./resize.ffi.mjs", "windowSize")
fn window_size() -> #(Int, Int)

fn get_window_size() -> Resolution {
  window_size()
  |> fn(z) {
    let #(x, y) = z
    Resolution(x: x, y: y)
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
    resolution: Resolution,
    offset: Vector,
    navigator: Navigator,
    mode: GraphMode,
    last_clicked_point: Vector,
  )
}

type Resolution {
  Resolution(x: Int, y: Int)
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
      resolution: get_window_size(),
      offset: Vector(0, 0),
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
  UserClickedGraph(MouseEvent)
  GraphClearSelection
  GraphSetDragMode
  GraphSetNormalMode
  GraphAddNodeToSelection(NodeId)
  GraphSetNodeAsSelection(NodeId)
  GraphResizeViewBox(Resolution)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedNode(node) -> #(
      Model(..model, nodes: list.append(model.nodes, [node])),
      effect.none(),
    )
    UserMovedMouse(point) -> #(
      model
        |> update_navigator_cursor_point(point)
        |> update_graph_offset
        |> update_node_positions,
      effect.none(),
    )
    UserClickedNode(node_id, mouse_event) -> #(
      model
        |> set_navigator_mouse_down
        |> update_all_node_offsets(mouse_event),
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
    GraphResizeViewBox(resolution) -> #(
      Model(..model, resolution: resolution),
      effect.none(),
    )
  }
}

fn update_navigator_cursor_point(model: Model, point: Vector) -> Model {
  point
  |> fn(p) { Navigator(..model.navigator, cursor_point: p) }
  |> fn(nav) { Model(..model, navigator: nav) }
}

fn set_navigator_mouse_down(model: Model) -> Model {
  Navigator(..model.navigator, mouse_down: True)
  |> fn(nav) { Model(..model, navigator: nav) }
}

fn update_last_clicked_point(model: Model, event: MouseEvent) -> Model {
  event.position
  |> fn(p) { Model(..model, last_clicked_point: vector.add(model.offset, p)) }
}

fn update_all_node_offsets(model: Model, event: MouseEvent) -> Model {
  model.nodes
  |> map(nd.update_offset(_, event.position))
  |> fn(x) { Model(..model, nodes: x) }
}

fn update_graph_offset(model: Model) -> Model {
  case model.mode {
    Normal -> model
    Drag ->
      Model(
        ..model,
        offset: navigator.calc_position(
            model.navigator,
            model.last_clicked_point,
          )
          |> navigator.inverse,
      )
  }
}

fn update_node_positions(model: Model) -> Model {
  let is_selected = fn(node: Node) {
    set.contains(model.nodes_selected, node.id)
  }
  let unselected = model.nodes |> filter(fn(x) { !is_selected(x) })

  model.nodes
  |> filter(is_selected)
  |> map(fn(node) {
    case model.navigator.mouse_down {
      False -> node
      True ->
        Node(
          ..node,
          position: navigator.calc_position(model.navigator, node.offset),
        )
    }
  })
  |> fn(nodes) { [unselected, nodes] |> list.concat }
  |> fn(nodes) { Model(..model, nodes: nodes) }
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

fn attr_viewbox(offset: Vector, resolution: Resolution) -> Attribute(Msg) {
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
        attr_viewbox(model.offset, model.resolution),
        attr("contentEditable", "true"),
        attr("graph-pos-x", int.to_string(model.navigator.cursor_point.x)),
        attr("graph-pos-y", int.to_string(model.navigator.cursor_point.y)),
        event.on("mousemove", user_moved_mouse),
        event.on("mousedown", mousedown),
        event.on_mouse_up(GraphSetNormalMode),
      ],
      model.nodes
        |> list.map(fn(node: Node) { view_node(node, model.nodes_selected) }),
    ),
  ])
}
