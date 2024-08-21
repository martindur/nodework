import gleam/dict
import gleam/set
import gleam/dynamic.{type DecodeError}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

import lustre
import lustre/attribute.{attribute as attr}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event

import nodework/decoder.{type MouseEvent}
import nodework/draw
import nodework/draw/viewbox.{ViewBox}
import nodework/handler.{simple_effect}
import nodework/handler/graph
import nodework/handler/user
import nodework/lib.{type NodeLibrary}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, type Msg, GraphClearSelection, GraphCloseMenu, GraphOpenMenu,
  GraphResizeViewBox, GraphSetDragMode, GraphSpawnNode, GraphAddNodeToSelection, GraphSetNodeAsSelection, Model, UserClickedGraph,
  UserClickedNode, UserClickedNodeOutput, UserHoverNodeInput,
  UserHoverNodeOutput, UserMovedMouse, UserPressedKey, UserUnclickedNode,
  UserUnhoverNodeInputs, UserUnhoverNodeOutputs,
}

import nodework/examples.{example_nodes}

pub type ResizeEvent

pub type MouseUpEvent

@external(javascript, "./nodework.ffi.mjs", "windowSize")
fn window_size() -> #(Int, Int)

fn get_window_size() -> Vector {
  window_size()
  |> fn(z) {
    let #(x, y) = z
    Vector(x: x, y: y)
  }
}

@external(javascript, "./nodework.ffi.mjs", "documentResizeEventListener")
fn document_resize_event_listener(listener: fn(ResizeEvent) -> Nil) -> Nil

@external(javascript, "./nodework.ffi.mjs", "mouseUpEventListener")
fn document_mouse_up_event_listener(listener: fn(MouseUpEvent) -> Nil) -> Nil

pub fn app() {
  lustre.application(init, update, view)
}

pub fn setup(runtime_call) {
  document_resize_event_listener(fn(_) {
    get_window_size()
    |> GraphResizeViewBox
    |> lustre.dispatch
    |> runtime_call
  })
  // document_mouse_up_event_listener(fn(_) {
  //   UserUnclicked
  //   |> lustre.dispatch
  //   |> runtime_call
  // })
}

pub fn main() {
  let app = lustre.application(init, update, view)

  let assert Ok(runtime_call) = lustre.start(app, "#app", example_nodes())

  setup(runtime_call)

  Nil
}

fn init(node_lib: NodeLibrary) -> #(Model, Effect(Msg)) {
  #(
    Model(
      lib: node_lib,
      menu: lib.generate_lib_menu(node_lib),
      nodes: dict.new(),
      nodes_selected: set.new(),
      window_resolution: get_window_size(),
      viewbox: ViewBox(Vector(0, 0), get_window_size(), 1.0),
      cursor: Vector(0, 0),
      last_clicked_point: Vector(0, 0),
      mouse_down: False
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GraphResizeViewBox(resolution) -> graph.resize_view_box(model, resolution)
    GraphOpenMenu -> graph.open_menu(model)
    GraphCloseMenu -> graph.close_menu(model)
    GraphSpawnNode(identifier) -> graph.spawn_node(model, identifier)
    GraphSetDragMode -> #(model, effect.none())
    GraphClearSelection -> #(model, effect.none())
    GraphAddNodeToSelection(node_id) -> graph.add_node_to_selection(model, node_id)
    GraphSetNodeAsSelection(node_id) -> graph.add_node_as_selection(model, node_id)
    UserPressedKey(key) -> user.pressed_key(model, key, key_lib)
    UserClickedGraph(event) -> user.clicked_graph(model, event)
    UserMovedMouse(position) -> user.moved_mouse(model, position)
    UserClickedNode(node_id, event) -> user.clicked_node(model, node_id, event)
    UserUnclickedNode -> user.unclicked_node(model)
    UserClickedNodeOutput(node_id, position) ->
      user.clicked_node_output(model, node_id, position)
    UserHoverNodeOutput(output_id) -> user.hover_node_output(model, output_id)
    UserUnhoverNodeOutputs -> user.unhover_node_outputs(model)
    UserHoverNodeInput(input_id) -> user.hover_node_input(model, input_id)
    UserUnhoverNodeInputs -> user.unhover_node_inputs(model)
  }
}

fn key_lib(key: String) -> Effect(Msg) {
  case string.lowercase(key) {
    // Spawn library menu
    "a" -> simple_effect(GraphOpenMenu)
    _ -> effect.none()
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let keydown = fn(e) -> Result(Msg, List(DecodeError)) {
    use key <- result.try(decoder.keydown_event_decoder(e))

    Ok(UserPressedKey(key))
  }

  let spawn = fn(e) -> Result(Msg, List(DecodeError)) {
    use target <- result.try(dynamic.field("target", dynamic.dynamic)(e))
    use dataset <- result.try(dynamic.field("dataset", dynamic.dynamic)(target))
    use identifier <- result.try(dynamic.field("identifier", dynamic.string)(
      dataset,
    ))

    Ok(GraphSpawnNode(identifier))
  }

  html.div([attr("tabindex", "0"), event.on("keydown", keydown)], [
    draw.view_canvas(model.viewbox, model.nodes, model.nodes_selected),
    draw.view_menu(model.menu, spawn),
  ])
}
