import gleam/dict
import gleam/io
import gleam/result
import gleam/set
import lustre/effect.{type Effect}
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, simple_effect}
import nodework/lib.{LibraryMenu}
import nodework/math.{type Vector}
import nodework/model.{type Model, type Msg, Model, GraphCloseMenu}
import nodework/node.{type UINode, type UINodeID}

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

pub fn spawn_node(model: Model, keypair: String) -> #(Model, Effect(Msg)) {
  let position = viewbox.transform(model.viewbox, model.menu.position)

  case lib.split_keypair(keypair) {
    Ok(#("int", key)) -> {
      lib.get_int_node(model.lib, key)
      |> result.map(fn(n) { n.inputs })
      |> result.unwrap(set.new())
    }
    Ok(#("string", key)) -> {
      lib.get_string_node(model.lib, key)
      |> result.map(fn(n) { n.inputs })
      |> result.unwrap(set.new())
    }
    Error(Nil) -> set.new()
    _ -> set.new()
  }
  |> node.new_ui_node(keypair, _, position)
  |> fn(n: UINode) { Model(..model, nodes: dict.insert(model.nodes, n.id, n)) }
  |> fn(m) { #(m, simple_effect(GraphCloseMenu)) }
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

pub fn delete_selected_ui_nodes(model: Model) -> #(Model, Effect(msg)) {
  model
  |> draw.delete_selected_nodes
  |> draw.delete_orphaned_connections
  // |> calc.sync_verts
  // |> calc.sync_edges
  // |> calc.recalc_graph
  |> none_effect_wrapper
}
