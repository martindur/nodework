import lustre/effect.{type Effect}

import nodework/decoder.{type MouseEvent}
import nodework/model.{type Msg, DragMode, GraphClearSelection, GraphSetMode}

pub fn none_effect_wrapper(model: a) -> #(a, Effect(msg)) {
  #(model, effect.none())
}

pub fn simple_effect(msg: msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    msg
    |> dispatch
  })
}

pub fn shift_key_check(event: MouseEvent) -> Effect(Msg) {
  effect.from(fn(dispatch) {
    case event.shift_key_active {
      True -> GraphSetMode(DragMode)
      False -> GraphClearSelection
    }
    |> dispatch
  })
}
