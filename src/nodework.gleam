import gleam/dict
import gleam/dynamic.{type DecodeError}
import gleam/io
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import nodework/util/storage

import lustre
import lustre/attribute.{attribute as attr}
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event

import nodework/dag
import nodework/dag_process as dp
import nodework/decoder
import nodework/draw/viewbox.{ViewBox}
import nodework/handler.{none_effect_wrapper, simple_effect}
import nodework/handler/graph
import nodework/handler/user
import nodework/lib.{type NodeLibrary}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, type Msg, GraphAddNodeToSelection, GraphChangedConnections,
  GraphClearSelection, GraphCloseMenu, GraphDeleteSelectedUINodes,
  GraphLoadGraph, GraphOpenMenu, GraphResizeViewBox, GraphSaveGraph,
  GraphSetMode, GraphSetNodeAsSelection, GraphSetTitleToReadMode, GraphSpawnNode,
  GraphTitle, Model, NormalMode, ReadMode, UserChangedGraphTitle,
  UserClickedCollectionItem, UserClickedConn, UserClickedGraph,
  UserClickedGraphTitle, UserClickedNewGraph, UserClickedNode,
  UserClickedNodeOutput, UserHoverNodeInput, UserHoverNodeOutput, UserMovedMouse,
  UserPressedKey, UserScrolled, UserUnclicked, UserUnclickedNode,
  UserUnhoverNodeInputs, UserUnhoverNodeOutputs,
}
import nodework/views

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
  document_mouse_up_event_listener(fn(_) {
    UserUnclicked
    |> lustre.dispatch
    |> runtime_call
  })
}

pub fn main() {
  let app = lustre.application(init, update, view)

  let assert Ok(runtime_call) = lustre.start(app, "#app", example_nodes())

  setup(runtime_call)

  Nil
}

fn init(node_lib: NodeLibrary) -> #(Model, Effect(Msg)) {
  let model =
    Model(
      lib: node_lib,
      menu: lib.generate_lib_menu(node_lib),
      collection: [],
      active_graph: "temp",
      nodes: dict.new(),
      connections: [],
      nodes_selected: set.new(),
      window_resolution: get_window_size(),
      viewbox: ViewBox(Vector(0, 0), get_window_size(), 1.0),
      cursor: Vector(0, 0),
      last_clicked_point: Vector(0, 0),
      mouse_down: False,
      mode: NormalMode,
      output: dynamic.from(""),
      graph: dag.new(),
      title: GraphTitle("Untitled", ReadMode),
      shortcuts_active: True,
    )

  case storage.get_from_storage("graph_0") {
    "" ->
      Model(..model, active_graph: "graph_0", collection: [
        #("graph_0", "Untitled"),
      ])
    json_graph -> storage.json_to_graph(model, json_graph)
  }
  |> fn(m) { Model(..m, collection: storage.load_collection()) }
  |> dp.sync_verts
  |> dp.sync_edges
  |> dp.recalc_graph
  |> fn(m) { #(m, effect.none()) }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GraphResizeViewBox(resolution) -> graph.resize_view_box(model, resolution)
    GraphOpenMenu -> graph.open_menu(model)
    GraphCloseMenu -> graph.close_menu(model)
    GraphSpawnNode(identifier) -> graph.spawn_node(model, identifier)
    GraphSetMode(mode) -> Model(..model, mode: mode) |> none_effect_wrapper
    GraphClearSelection -> graph.clear_selection(model)
    GraphAddNodeToSelection(node_id) ->
      graph.add_node_to_selection(model, node_id)
    GraphSetNodeAsSelection(node_id) ->
      graph.add_node_as_selection(model, node_id)
    GraphChangedConnections -> graph.changed_connections(model)
    GraphDeleteSelectedUINodes -> graph.delete_selected_ui_nodes(model)
    GraphSaveGraph -> graph.save_graph(model)
    GraphLoadGraph(graph_id) -> graph.load_graph(model, graph_id)
    GraphSetTitleToReadMode -> graph.set_title_to_readmode(model)
    UserPressedKey(key) -> user.pressed_key(model, key, key_lib)
    UserScrolled(delta_y) -> user.scrolled(model, delta_y)
    UserClickedGraph(event) -> user.clicked_graph(model, event)
    UserClickedGraphTitle -> user.clicked_graph_title(model)
    UserUnclicked -> user.unclicked(model)
    UserMovedMouse(position) -> user.moved_mouse(model, position)
    UserClickedNode(node_id, event) -> user.clicked_node(model, node_id, event)
    UserUnclickedNode -> user.unclicked_node(model)
    UserClickedNodeOutput(node_id, position) ->
      user.clicked_node_output(model, node_id, position)
    UserHoverNodeOutput(output_id) -> user.hover_node_output(model, output_id)
    UserUnhoverNodeOutputs -> user.unhover_node_outputs(model)
    UserHoverNodeInput(input_id) -> user.hover_node_input(model, input_id)
    UserUnhoverNodeInputs -> user.unhover_node_inputs(model)
    UserClickedConn(conn_id, event) -> user.clicked_conn(model, conn_id, event)
    UserChangedGraphTitle(value) -> user.changed_graph_title(model, value)
    UserClickedCollectionItem(graph_id) ->
      user.clicked_collection_item(model, graph_id)
    UserClickedNewGraph -> user.new_graph(model)
  }
}

fn key_lib(key: String) -> Effect(Msg) {
  case string.lowercase(key) {
    // Spawn library menu
    "a" -> simple_effect(GraphOpenMenu)
    "backspace" -> simple_effect(GraphDeleteSelectedUINodes)
    "delete" -> simple_effect(GraphDeleteSelectedUINodes)
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

  html.div(
    [
      attribute.class("text-neutral-800"),
      attr("tabindex", "0"),
      event.on("keydown", keydown),
    ],
    [
      html.div([attribute.class("absolute left-2 top-2 text-2xl")], [
        views.view_graph_title(model.title),
      ]),
      html.div([attribute.class("absolute right-2 top-2")], [
        views.view_collection(model.collection, model.active_graph),
      ]),
      views.view_graph(
        model.viewbox,
        model.nodes,
        model.nodes_selected,
        model.connections,
      ),
      views.view_menu(model.menu, spawn),
      views.view_output_canvas(model),
    ],
  )
}
