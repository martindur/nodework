import gleam/dynamic.{type DecodeError}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import lustre
import lustre/attribute.{type Attribute, attribute as attr}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/element/svg
import lustre/event

import graph_utils.{type Position, Position, translate_node}

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
  Node(position: Position, id: NodeId, selected: Bool)
}

type MouseEvent {
  MouseEvent(position: #(Int, Int), shift_key_active: Bool)
}

type Model {
  Model(
    nodes: List(Node),
    nodes_selected: Set(NodeId),
    cursor: Position,
    clicked_point: Position,
    clicked_node: NodeId,
    resolution: Resolution,
    offset: Offset,
    mouse_down: Bool,
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
        Node(position: Position(x: 0, y: 0), id: 0, selected: False),
        Node(position: Position(x: 300, y: 300), id: 1, selected: False),
      ],
      set.new(),
      Position(x: 0, y: 0),
      Position(x: 0, y: 0),
      -1,
      get_window_size(),
      Offset(x: 0, y: 0),
      False,
    ),
    effect.none(),
  )
}

pub opaque type Msg {
  UserAddedNode(Node)
  UserMovedMouse(Position)
  UserClickedNode(NodeId, MouseEvent)
  UserUnclickedNode(NodeId)
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
      Model(..model, cursor: Position(cursor.x, cursor.y))
        |> update_node_positions,
      effect.none(),
    )
    UserClickedNode(node_id, mouse_event) -> #(
      Model(
        ..model,
        clicked_point: Position(mouse_event.position.0, mouse_event.position.1),
        clicked_node: node_id,
        mouse_down: True,
      ),
      update_node_selection(mouse_event, node_id),
    )
    UserUnclickedNode(_node_id) -> #(
      Model(..model, mouse_down: False),
      effect.none(),
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

fn diff(a: Position, b: Position) -> Position {
   Position(x: a.x - b.x, y: a.y - b.y) 
}

fn add(a: Position, b: Position) -> Position {
  Position(x: a.x + b.x, y: a.y + b.y)
}

fn update_node_positions(model: Model) -> Model {
  case list.find(model.nodes, fn(n) { n.id == model.clicked_node }) {
    Error(Nil) -> model
    Ok(node) -> {
      let offset = Position(x: node.position.x - model.clicked_point.x, y: node.position.y - model.clicked_point.y)
      let updated_nodes =
        model.nodes
        |> list.map(fn(node) {
          case set.contains(model.nodes_selected, node.id) {
            False -> node
            // True -> Node(..node, position: translate_node(model.clicked_point, model.cursor, offset))
            True -> Node(..node, position: diff(model.clicked_point, model.cursor) |> add(node.position))
          }
        })

      Model(..model, nodes: updated_nodes)
    }
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

  Ok(MouseEvent(position: #(float.round(position.0), float.round(position.1)), shift_key_active: shift_key))
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
      Ok(res) -> attr("viewBox", res)
      Error(_) -> attr("viewBox", "0 0 100 100")
    }
  }
}

fn view_node(node: Node, selection: Set(NodeId)) -> element.Element(Msg) {
  let node_selected_attr = case set.contains(selection, node.id) {
    True -> attr("stroke-width", "2")
    False -> attr("stroke-width", "0")
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedNode(node.id, decoded_event))
  }

  svg.rect([
    attribute.id(int.to_string(node.id)),
    attr("width", "200"),
    attr("height", "150"),
    attr("rx", "25"),
    attr("ry", "25"),
    attr("fill", "currentColor"),
    attr("stroke", "currentColor"),
    attr("transform", translate(node.position.x, node.position.y)),
    node_selected_attr,
    attribute.class("text-gray-300 stroke-gray-400"),
    event.on("mousedown", mousedown),
    event.on_mouse_up(UserUnclickedNode(node.id)),
  ])
}

fn view(model: Model) -> element.Element(Msg) {
  let user_moved_mouse = fn(e) -> Result(Msg, List(DecodeError)) {
    result.try(event.mouse_position(e), fn(pos) {
      Ok(UserMovedMouse(Position(x: float.round(pos.0), y: float.round(pos.1))))
    })
  }

  html.div([], [
    svg.svg(
      [
        attribute.id("graph"),
        attr_viewbox(model.offset, model.resolution),
        attr("contentEditable", "true"),
        attr("graph-pos-x", int.to_string(model.cursor.x)),
        attr("graph-pos-y", int.to_string(model.cursor.y)),
        attr("graph-clicked-x", int.to_string(model.clicked_point.x)),
        attr("graph-clicked-y", int.to_string(model.clicked_point.y)),
        event.on("mousemove", user_moved_mouse),
        event.on_mouse_down(UserClickedGraph),
      ],
      model.nodes
        |> list.map(fn(node: Node) { view_node(node, model.nodes_selected) }),
    ),
  ])
}
