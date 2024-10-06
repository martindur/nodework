import gleam/list
import gleam/pair
import gleam/dict
import gleam/set
import lustre/effect.{type Effect}
import nodework/conn
import nodework/dag_process as dp
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, simple_effect}
import nodework/lib.{LibraryMenu}
import nodework/math.{type Vector}
import nodework/model.{type Model, type Msg, GraphCloseMenu, GraphSaveGraph, Model, GraphTitle, ReadMode}
import nodework/node.{type UINode, type UINodeID}
import nodework/util/storage.{save_to_storage, graph_to_json}

pub fn resize_view_box(
  model: Model,
  resolution: Vector,
) -> #(Model, Effect(msg)) {
  Model(
    ..model,
    window_resolution: resolution,
    viewbox: viewbox.update_resolution(model.viewbox, resolution),
  )
  |> none_effect_wrapper
}

pub fn open_menu(model: Model) -> #(Model, Effect(msg)) {
  model.cursor
  // we don't zoom the menu, so we don't want a scaled cursor
  |> viewbox.unscale(model.viewbox, _)
  |> fn(cursor) { LibraryMenu(..model.menu, position: cursor, visible: True) }
  |> fn(menu) { Model(..model, menu: menu) }
  |> none_effect_wrapper
}

pub fn close_menu(model: Model) -> #(Model, Effect(msg)) {
  LibraryMenu(..model.menu, visible: False)
  |> fn(menu) { Model(..model, menu: menu) }
  |> none_effect_wrapper
}

pub fn spawn_node(model: Model, key: String) -> #(Model, Effect(Msg)) {
  let position = viewbox.transform(model.viewbox, model.menu.position)

  case dict.get(model.lib.nodes, key) {
    Ok(n) ->
      n
      |> node.new_ui_node(position)
      |> fn(n: UINode) {
        save_to_storage("node", n.id)
        Model(..model, nodes: dict.insert(model.nodes, n.id, n))
      }
    Error(Nil) -> model
  }
  |> dp.sync_verts
  |> dp.recalc_graph
  |> fn(m) { #(m, effect.batch([simple_effect(GraphCloseMenu), simple_effect(GraphSaveGraph)])) }
}

pub fn add_node_to_selection(
  model: Model,
  id: UINodeID,
) -> #(Model, Effect(msg)) {
  Model(..model, nodes_selected: model.nodes_selected |> set.insert(id))
  |> none_effect_wrapper
}

pub fn add_node_as_selection(
  model: Model,
  id: UINodeID,
) -> #(Model, Effect(msg)) {
  Model(..model, nodes_selected: set.new() |> set.insert(id))
  |> none_effect_wrapper
}

pub fn clear_selection(model: Model) -> #(Model, Effect(msg)) {
  Model(..model, nodes_selected: set.new())
  |> none_effect_wrapper
}

fn delete_selected_nodes(m: Model) -> Model {
  m.nodes
  |> node.exclude_by_ids(m.nodes_selected)
  |> fn(nodes) { Model(..m, nodes: nodes) }
}

fn delete_orphaned_connections(m: Model) -> Model {
  m.connections
  |> conn.exclude_by_node_ids(m.nodes_selected)
  |> fn(conns) { Model(..m, connections: conns) }
}

pub fn delete_selected_ui_nodes(model: Model) -> #(Model, Effect(msg)) {
  model
  |> delete_selected_nodes
  |> delete_orphaned_connections
  |> dp.sync_verts
  |> dp.sync_edges
  |> dp.recalc_graph
  |> none_effect_wrapper
}

pub fn changed_connections(model: Model) -> #(Model, Effect(msg)) {
  model
  |> none_effect_wrapper
  // model.connections
  // |> recalc?
}

pub fn save_graph(model: Model) -> #(Model, Effect(msg)) {
  model
  |> graph_to_json 
  |> save_to_storage("graph", _)

  model
  |> none_effect_wrapper
}

pub fn set_title_to_readmode(model: Model) -> #(Model, Effect(msg)) {
  Model(..model, title: GraphTitle(..model.title, mode: ReadMode))
  |> none_effect_wrapper
}
