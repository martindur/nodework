import gleam/dynamic.{type DecodeError}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/element/svg
import lustre/event

pub type ResizeEvent

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

type NodeId =
  Int

type Node {
  Node(x: Int, y: Int, id: NodeId, selected: Bool)
}

type Cursor {
  Cursor(x: Float, y: Float)
}

type MouseEvent {
  MouseEvent(position: #(Float, Float), shift_key_active: Bool)
}

type Model {
  Model(
    nodes: List(Node),
    nodes_selected: Set(NodeId),
    cursor: Cursor,
    resolution: Resolution,
    offset: Offset,
  )
}

type Resolution {
  Resolution(x: Int, y: Int)
}

type Offset {
  Offset(x: Int, y: Int)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(
    Model(
      [
        Node(x: 0, y: 0, id: 0, selected: False),
        Node(x: 300, y: 300, id: 1, selected: False),
      ],
      set.new(),
      Cursor(x: 0.0, y: 0.0),
      get_window_size(),
      Offset(x: 0, y: 0),
    ),
    effect.none(),
  )
}

pub opaque type Msg {
  UserAddedNode(Node)
  UserMovedMouse(Cursor)
  UserClickedNode(NodeId, MouseEvent)
  UserClickedGraph
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
    UserMovedMouse(cursor) -> #(
      Model(..model, cursor: Cursor(cursor.x, cursor.y)),
      effect.none(),
    )
    UserClickedNode(node_id, mouse_event) -> #(
      model,
      update_node_selection(mouse_event, node_id),
    )
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
    UserClickedGraph -> #(
      Model(..model, nodes_selected: set.new()),
      effect.none(),
    )
    GraphResizeViewBox(resolution) -> #(
      Model(..model, resolution: resolution),
      effect.none(),
    )
  }
}

fn update_node_selection(event: MouseEvent, node_id: NodeId) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case event.shift_key_active {
      True -> GraphAddNodeToSelection(node_id)
      False -> GraphSetNodeAsSelection(node_id)
    }
    |> dispatch
  })
}

fn mouse_event_decoder(e) -> Result(MouseEvent, List(DecodeError)) {
  event.stop_propagation(e)

  use shift_key <- result.try(dynamic.field("shiftKey", dynamic.bool)(e))
  use position <- result.try(event.mouse_position(e))

  Ok(MouseEvent(position: position, shift_key_active: shift_key))
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

fn attr_viewbox(offset: Offset, resolution: Resolution) -> Attribute(Msg) {
  [offset.x, offset.y, resolution.x, resolution.y]
  |> list.map(int.to_string)
  |> list.reduce(fn(a, b) { a <> " " <> b })
  |> fn(result) {
    case result {
      Ok(res) -> attribute.attribute("viewBox", res)
      Error(_) -> attribute.attribute("viewBox", "0 0 100 100")
    }
  }
}

fn view_node(node: Node, selection: Set(NodeId)) -> element.Element(Msg) {
  let node_selected_attr = case set.contains(selection, node.id) {
    True -> attribute.attribute("stroke-width", "2")
    False -> attribute.attribute("stroke-width", "0")
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedNode(node.id, decoded_event))
  }

  svg.rect([
    attribute.id(int.to_string(node.id)),
    attribute.attribute("width", "200"),
    attribute.attribute("height", "150"),
    attribute.attribute("rx", "25"),
    attribute.attribute("ry", "25"),
    attribute.attribute("fill", "currentColor"),
    attribute.attribute("stroke", "currentColor"),
    attribute.attribute("transform", translate(node.x, node.y)),
    node_selected_attr,
    attribute.class("text-gray-300 stroke-gray-400"),
    event.on("mousedown", mousedown),
  ])
}

fn view(model: Model) -> element.Element(Msg) {
  let user_moved_mouse = fn(e) -> Result(Msg, List(DecodeError)) {
    result.try(event.mouse_position(e), fn(pos) {
      Ok(UserMovedMouse(Cursor(x: pos.0, y: pos.1)))
    })
  }

  html.div([], [
    svg.svg(
      [
        attribute.id("graph"),
        attr_viewbox(model.offset, model.resolution),
        attribute.attribute("contentEditable", "true"),
        attribute.attribute("graph-pos", float.to_string(model.cursor.x)),
        event.on("mousemove", user_moved_mouse),
        event.on_mouse_down(UserClickedGraph),
      ],
      model.nodes
        |> list.map(fn(node: Node) { view_node(node, model.nodes_selected) }),
    ),
  ])
}
