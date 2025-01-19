import gleam/dict
import gleam/int
import gleam/io
import gleam/list

import lustre/effect.{type Effect}

import nodework/conn.{type Conn, type ConnID, Conn}
import nodework/dag_process as dp
import nodework/decoder.{type MouseEvent}
import nodework/draw
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, shift_key_check, simple_effect}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, type Msg, type UIGraphID, GraphAddNodeToSelection, GraphCloseMenu,
  GraphLoadGraph, GraphSaveCollection, GraphSetNodeAsSelection, Model, UIGraph,
  new_graph,
}
import nodework/node.{
  type UINodeID, type UINodeInputID, type UINodeOutputID, NodeInput,
  NodeNotFound, NodeOutput,
}
import nodework/util/random

const graph_limit = 500

pub fn pressed_key(
  model: Model,
  key: String,
  func: fn(String) -> Effect(msg),
) -> #(Model, Effect(msg)) {
  case model.shortcuts_active {
    True -> #(model, func(key))
    False -> model |> none_effect_wrapper
  }
}

pub fn clicked_graph(model: Model, event: MouseEvent) -> #(Model, Effect(Msg)) {
  model
  |> update_last_clicked_point(event)
  |> fn(m) {
    #(
      Model(..m, shortcuts_active: True),
      effect.batch([shift_key_check(event), simple_effect(GraphCloseMenu)]),
    )
  }
}

pub fn unclicked(m: Model) -> #(Model, Effect(Msg)) {
  case node.get_node_from_input_hovered(m.graph.nodes) {
    Error(NodeNotFound) -> m.graph.connections
    Ok(#(n, input)) -> {
      m.graph.connections
      |> conn.map_dragged(fn(c) {
        case node.extract_node_id(c.from) != n.id {
          False -> c
          True -> Conn(..c, to: input.id, value: input.label, dragged: False)
        }
      })
    }
  }
  |> list.filter(fn(c) { node.extract_node_id(c.to) != "" && c.dragged != True })
  |> conn.unique
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
  |> dp.sync_edges
  |> dp.recalc_dag
  |> none_effect_wrapper
  // |> fn(m) { #(m, simple_effect(GraphSaveCollection)) } // Testing if this has a "bad" impact
}

// TODO: shortcuts active should be based on focus/blur of input
pub fn clicked_graph_title(m: Model) -> #(Model, Effect(Msg)) {
  Model(..m, shortcuts_active: False)
  |> none_effect_wrapper
}

pub fn clicked_node(
  model: Model,
  node_id: UINodeID,
  event: MouseEvent,
) -> #(Model, Effect(Msg)) {
  model
  |> fn(m) {
    Model(
      ..m,
      mouse_down: True,
      graph: UIGraph(
        ..m.graph,
        nodes: m.graph.nodes |> node.update_all_node_offsets(m.cursor),
      ),
    )
  }
  |> fn(m) {
    #(
      Model(..m, shortcuts_active: True),
      effect.batch([
        update_selected_nodes(event, node_id),
        simple_effect(GraphCloseMenu),
      ]),
    )
  }
}

pub fn unclicked_node(model: Model) -> #(Model, Effect(Msg)) {
  Model(..model, mouse_down: False)
  |> fn(m) { #(m, simple_effect(GraphSaveCollection)) }
}

pub fn clicked_node_output(
  m: Model,
  node_id: UINodeID,
  offset: Vector,
) -> #(Model, Effect(Msg)) {
  let #(p1, output_id) = case node.get_ui_node(m.graph.nodes, node_id) {
    Ok(node) -> #(node.position |> math.vector_add(offset), node.output.id)
    Error(Nil) -> #(Vector(0, 0), "")
  }
  let p2 = m.viewbox |> viewbox.translate(m.cursor)
  let id = random.generate_random_id("conn")
  let new_conn = Conn(id, p1, p2, output_id, "", "", True)

  m.graph.connections
  |> list.prepend(new_conn)
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
  |> none_effect_wrapper
}

pub fn hover_node_output(
  m: Model,
  output_id: UINodeOutputID,
) -> #(Model, Effect(Msg)) {
  m.graph.nodes
  |> node.set_hover(NodeOutput(output_id), True)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
  |> none_effect_wrapper
}

pub fn unhover_node_outputs(m: Model) -> #(Model, Effect(Msg)) {
  m.graph.nodes
  |> node.set_hover(NodeOutput(""), False)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
  |> none_effect_wrapper
}

pub fn hover_node_input(
  m: Model,
  input_id: UINodeInputID,
) -> #(Model, Effect(Msg)) {
  m.graph.nodes
  |> node.set_hover(NodeInput(input_id), True)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
  |> none_effect_wrapper
}

pub fn unhover_node_inputs(m: Model) -> #(Model, Effect(Msg)) {
  m.graph.nodes
  |> node.set_hover(NodeInput(""), False)
  |> fn(nodes) { Model(..m, graph: UIGraph(..m.graph, nodes:)) }
  |> none_effect_wrapper
}

pub fn moved_mouse(m: Model, position: Vector) -> #(Model, Effect(Msg)) {
  m
  |> draw.cursor(position)
  |> draw.viewbox_offset(graph_limit)
  |> draw.nodes
  |> draw.dragged_connection
  |> draw.connections
  |> none_effect_wrapper
}

pub fn clicked_conn(
  m: Model,
  clicked_id: ConnID,
  event: MouseEvent,
) -> #(Model, Effect(Msg)) {
  m.graph.connections
  |> list.map(fn(c) {
    case c.id == clicked_id {
      False -> c
      True -> Conn(..c, p1: event.position, to: "", dragged: True)
    }
  })
  |> fn(connections) { Model(..m, graph: UIGraph(..m.graph, connections:)) }
  |> draw.dragged_connection
  |> none_effect_wrapper
}

pub fn scrolled(m: Model, delta_y: Float) -> #(Model, Effect(Msg)) {
  m.viewbox
  |> viewbox.update_zoom_level(delta_y)
  |> viewbox.update_resolution(m.window_resolution)
  |> fn(vb) { Model(..m, viewbox: vb) }
  |> none_effect_wrapper
}

fn update_last_clicked_point(m: Model, event: MouseEvent) -> Model {
  event.position
  |> viewbox.transform(m.viewbox, _)
  |> fn(p) { Model(..m, last_clicked_point: p) }
}

fn update_selected_nodes(event: MouseEvent, node_id: UINodeID) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case event.shift_key_active {
      True -> GraphAddNodeToSelection(node_id)
      False -> GraphSetNodeAsSelection(node_id)
    }
    |> dispatch
  })
}

pub fn changed_graph_title(m: Model, value: String) -> #(Model, Effect(Msg)) {
  let graph = UIGraph(..m.graph, title: value)
  Model(..m, graph:, collection: dict.insert(m.collection, graph.id, graph))
  |> fn(m) { #(m, simple_effect(GraphSaveCollection)) }
}

pub fn clicked_collection_item(
  m: Model,
  graph_id: UIGraphID,
) -> #(Model, Effect(Msg)) {
  #(m, simple_effect(GraphLoadGraph(graph_id)))
}

pub fn create_graph(m: Model) -> #(Model, Effect(Msg)) {
  let graph = new_graph()

  Model(..m, graph:, collection: dict.insert(m.collection, graph.id, graph))
  |> fn(m) { #(m, simple_effect(GraphSaveCollection)) }
}
