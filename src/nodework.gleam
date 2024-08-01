import gleam/io
import gleam/int
import gleam/list
import gleam/dict
import gleam/string
import gleam/result
import gleam/dynamic.{type DecodeError}

import lustre
import lustre/event
import lustre/attribute.{attribute as attr}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html

import nodework/draw
import nodework/decoder.{type MouseEvent}
import nodework/draw/viewbox.{ViewBox}
import nodework/handler.{simple_effect}
import nodework/handler/graph
import nodework/handler/user
import nodework/lib.{type NodeLibrary}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, Model, 
  type Msg,
  GraphResizeViewBox,
  GraphOpenMenu,
  GraphCloseMenu,
  GraphSpawnNode,
  GraphSetDragMode,
  GraphClearSelection,
  UserPressedKey,
  UserClickedGraph,
  UserMovedMouse,
  UserClickedNode,
  UserUnclickedNode
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

  let assert Ok(_) = lustre.start(app, "#app", example_nodes())

  Nil
}

fn init(node_lib: NodeLibrary) -> #(Model, Effect(Msg)) {
  #(
    Model(
      lib: node_lib,
      menu: lib.generate_lib_menu(node_lib),
      nodes: dict.new(),
      window_resolution: get_window_size(),
      viewbox: ViewBox(Vector(0, 0), get_window_size(), 1.0),
      cursor: Vector(0, 0),
      last_clicked_point: Vector(0, 0)
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
    UserPressedKey(key) -> user.pressed_key(model, key, key_lib)
    UserClickedGraph(event) -> user.clicked_graph(model, event)
    UserMovedMouse(position) -> user.moved_mouse(model, position)
    UserClickedNode(node_id, event) -> user.clicked_node(model, node_id, event)
    UserUnclickedNode(node_id) -> user.unclicked_node(model, node_id)
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
    use identifier <- result.try(dynamic.field("identifier", dynamic.string)(dataset))

    Ok(GraphSpawnNode(identifier))
  }

  html.div([attr("tabindex", "0"), event.on("keydown", keydown)], [
    draw.view_canvas(model.viewbox, model.nodes),
    draw.view_menu(model.menu, spawn)
  ])
}
