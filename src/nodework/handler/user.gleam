import lustre/effect.{type Effect}

import nodework/decoder.{type MouseEvent}
import nodework/util/random
import nodework/draw
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper, shift_key_check, simple_effect}
import nodework/math.{type Vector, Vector}
import nodework/model.{type Model, type Msg, Model, GraphCloseMenu, GraphAddNodeToSelection, GraphSetNodeAsSelection}
import nodework/node.{type UINodeID, type UINodeOutputID, type UINodeInputID, NodeInput, NodeOutput}

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
      nodes: m.nodes |> node.update_all_node_offsets(m.cursor)
    )}
  |> fn(m) {
    #(
      m,
      effect.batch([
        update_selected_nodes(event, node_id),
        simple_effect(GraphCloseMenu)
      ])
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
  // let new_conn = Conn(id, p1, p2, node_id, "", "", "", True)

  // model.connections
  // |> list.prepend(new_conn)
  // |> fn(c) { Model(..model, connections: c) }
  model
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

pub fn hover_node_input(model: Model, input_id: UINodeInputID) -> #(Model, Effect(Msg)) {
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
  |> none_effect_wrapper
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
