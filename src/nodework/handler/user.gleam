import lustre/effect.{type Effect}

import nodework/math.{type Vector}
import nodework/decoder.{type MouseEvent}
import nodework/handler.{none_effect_wrapper, simple_effect, shift_key_check}
import nodework/model.{type Model, Model, type Msg, GraphCloseMenu}
import nodework/draw
import nodework/draw/viewbox

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
