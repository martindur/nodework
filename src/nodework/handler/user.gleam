import gleam/list.{map}

import lustre/effect.{type Effect}

import nodework/conn.{type Conn, type ConnID, Conn}
import nodework/decoder.{type MouseEvent}
import nodework/draw
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, shift_key_check, simple_effect}
import nodework/math.{type Vector, Vector}
import nodework/model.{
  type Model, type Msg, GraphAddNodeToSelection, GraphCloseMenu,
  GraphSetNodeAsSelection, Model,
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
  model
  |> fn(m) { #(m, func(key)) }
}

pub fn clicked_graph(model: Model, event: MouseEvent) -> #(Model, Effect(Msg)) {
  model
  |> update_last_clicked_point(event)
  |> fn(m) {
    #(m, effect.batch([shift_key_check(event), simple_effect(GraphCloseMenu)]))
  }
}

pub fn unclicked(model: Model) -> #(Model, Effect(Msg)) {
  case node.get_node_from_input_hovered(model.nodes) {
    Error(NodeNotFound) -> model.connections
    Ok(#(node, input)) -> {
      model.connections
      |> conn.map_dragged(fn(c) {
        case c.source_node_id != node.id {
          False -> c
          True ->
            Conn(
              ..c,
              target_node_id: node.id,
              target_input_id: input.id,
              target_input_value: input.label,
              dragged: False,
            )
        }
      })
    }
  }
  |> list.filter(fn(c) { c.target_node_id != "" && c.dragged != True })
  |> conn.unique
  |> fn(c) { Model(..model, connections: c) }
  // |> calc.sync_edges
  // |> calc.recalc_graph
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
      nodes: m.nodes |> node.update_all_node_offsets(m.cursor),
    )
  }
  |> fn(m) {
    #(
      m,
      effect.batch([
        update_selected_nodes(event, node_id),
        simple_effect(GraphCloseMenu),
      ]),
    )
  }
}

pub fn unclicked_node(model: Model) -> #(Model, Effect(Msg)) {
  Model(..model, mouse_down: False)
  |> none_effect_wrapper
}

pub fn clicked_node_output(
  model: Model,
  node_id: UINodeID,
  offset: Vector,
) -> #(Model, Effect(Msg)) {
  let p1 = case node.get_node(model.nodes, node_id) {
    Ok(node) -> node.position |> math.vector_add(offset)
    Error(Nil) -> Vector(0, 0)
  }
  let p2 = model.viewbox |> viewbox.translate(model.cursor)
  let id = random.generate_random_id("conn")
  let new_conn = Conn(id, p1, p2, node_id, "", "", "", True)

  model.connections
  |> list.prepend(new_conn)
  |> fn(c) { Model(..model, connections: c) }
  |> none_effect_wrapper
}

pub fn hover_node_output(
  model: Model,
  output_id: UINodeOutputID,
) -> #(Model, Effect(Msg)) {
  model.nodes
  |> node.set_hover(NodeOutput(output_id), True)
  |> fn(nodes) { Model(..model, nodes: nodes) }
  |> none_effect_wrapper
}

pub fn unhover_node_outputs(model: Model) -> #(Model, Effect(Msg)) {
  model.nodes
  |> node.set_hover(NodeOutput(""), False)
  |> fn(nodes) { Model(..model, nodes: nodes) }
  |> none_effect_wrapper
}

pub fn hover_node_input(
  model: Model,
  input_id: UINodeInputID,
) -> #(Model, Effect(Msg)) {
  model.nodes
  |> node.set_hover(NodeInput(input_id), True)
  |> fn(nodes) { Model(..model, nodes: nodes) }
  |> none_effect_wrapper
}

pub fn unhover_node_inputs(model: Model) -> #(Model, Effect(Msg)) {
  model.nodes
  |> node.set_hover(NodeInput(""), False)
  |> fn(nodes) { Model(..model, nodes: nodes) }
  |> none_effect_wrapper
}

pub fn moved_mouse(model: Model, position: Vector) -> #(Model, Effect(Msg)) {
  model
  |> draw.cursor(position)
  |> draw.viewbox_offset(graph_limit)
  |> draw.nodes
  |> draw.dragged_connection
  |> draw.connections
  |> none_effect_wrapper
}

pub fn clicked_conn(
  model: Model,
  clicked_id: ConnID,
  event: MouseEvent,
) -> #(Model, Effect(Msg)) {
  model.connections
  |> list.map(fn(c) {
    case c.id == clicked_id {
      False -> c
      True ->
        Conn(
          ..c,
          p1: event.position,
          target_node_id: "",
          target_input_id: "",
          dragged: True,
        )
    }
  })
  |> fn(conns) { Model(..model, connections: conns) }
  |> none_effect_wrapper
}

pub fn scrolled(model: Model, amount: Float) -> #(Model, Effect(Msg)) {
  todo
}

fn update_last_clicked_point(model: Model, event: MouseEvent) -> Model {
  event.position
  |> viewbox.transform(model.viewbox, _)
  |> fn(p) { Model(..model, last_clicked_point: p) }
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
