import lustre/effect.{type Effect}

pub fn none_effect_wrapper(model: a) -> #(a, Effect(msg)) {
  #(model, effect.none())
}

pub fn simple_effect(msg: msg) -> Effect(msg) {
  effect.from(fn(dispatch) {
    msg
    |> dispatch
  })
}
