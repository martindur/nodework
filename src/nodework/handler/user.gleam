import lustre/effect.{type Effect}

import nodework/handler.{none_effect_wrapper}
import nodework/model.{type Model}

pub fn pressed_key(
  model: Model,
  key: String,
  func: fn(String) -> Effect(msg),
) -> #(Model, Effect(msg)) {
  model
  |> fn(m) { #(m, func(key)) }
}
