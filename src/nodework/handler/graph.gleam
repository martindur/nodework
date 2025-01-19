import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/set
import lustre/effect.{type Effect}
import nodework/conn.{type Conn}
import nodework/dag_process as dp
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, simple_effect}
import nodework/lib.{LibraryMenu}
import nodework/math.{type Vector}
import nodework/model.{
  type Model, type Msg, type UIGraph, type UIGraphID, GraphCloseMenu,
  GraphSaveCollection, Model, UIGraph,
}
import nodework/node.{type UINode, type UINodeID}
import nodework/util/storage

pub fn resize_view_box(
  model: Model,
  window_resolution: Vector,
) -> #(Model, Effect(msg)) {
  Model(
    ..model,
    window_resolution:,
    viewbox: viewbox.update_resolution(model.viewbox, window_resolution),
  )
  |> none_effect_wrapper
}

pub fn open_menu(model: Model) -> #(Model, Effect(msg)) {
  model.cursor
  // we don't zoom the menu, so we don't want a scaled cursor
  |> viewbox.unscale(model.viewbox, _)
  |> fn(cursor) { LibraryMenu(..model.menu, position: cursor, visible: True) }
  |> fn(menu) { Model(..model, menu:) }
  |> none_effect_wrapper
}

pub fn close_menu(model: Model) -> #(Model, Effect(msg)) {
  LibraryMenu(..model.menu, visible: False)
  |> fn(menu) { Model(..model, menu:) }
  |> none_effect_wrapper
}

pub fn spawn_node(model: Model, key: String) -> #(Model, Effect(Msg)) {
  let position = viewbox.transform(model.viewbox, model.menu.position)

  case dict.get(model.lib.nodes, key) {
    Ok(n) ->
      n
      |> node.new_ui_node(position)
      |> fn(n: UINode) {
        Model(
          ..model,
          graph: UIGraph(
            ..model.graph,
            nodes: dict.insert(model.graph.nodes, n.id, n),
          ),
        )
      }
    Error(Nil) -> model
  }
  |> dp.sync_verts
  |> dp.recalc_dag
  |> fn(m) {
    #(
      m,
      effect.batch([
        simple_effect(GraphCloseMenu),
        simple_effect(GraphSaveCollection),
      ]),
    )
  }
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
  m.graph.nodes
  |> node.exclude_by_ids(m.nodes_selected)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
}

fn delete_orphaned_connections(m: Model) -> Model {
  m.graph.connections
  |> conn.exclude_by_node_ids(m.nodes_selected)
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
}

pub fn delete_selected_ui_nodes(model: Model) -> #(Model, Effect(msg)) {
  model
  |> delete_selected_nodes
  |> delete_orphaned_connections
  |> dp.sync_verts
  |> dp.sync_edges
  |> dp.recalc_dag
  |> none_effect_wrapper
}

pub fn changed_connections(model: Model) -> #(Model, Effect(msg)) {
  model
  |> none_effect_wrapper
  // model.connections
  // |> recalc?
}

// pub fn save_graph(model: Model) -> #(Model, Effect(msg)) {
//   model
//   |> storage.graph_to_json_string
//   |> storage.save_to_storage(model.graph, _)

//   model
//   |> none_effect_wrapper
// }

pub fn save_collection(model: Model) -> #(Model, Effect(msg)) {
  model
  |> storage.collection_to_json_string
  |> io.debug
  |> storage.save_to_storage("nodework_graph_collection", _)

  model
  |> none_effect_wrapper
}

pub fn load_graph(model: Model, graph_id: UIGraphID) -> #(Model, Effect(msg)) {
  storage.load_collection()
  |> fn(collection) {
    let graph =
      collection
      |> dict.to_list
      |> list.key_find(graph_id)
      |> fn(res) {
        case res {
          Ok(graph) -> graph
          // TODO: Maybe add some error messages, e.g. notifies?
          Error(Nil) -> model.graph
        }
      }

    Model(..model, collection:, graph:)
  }
  |> none_effect_wrapper
}
