import gleam/dynamic.{type DecodeError}
import gleam/float
import gleam/result

import lustre/event

import nodework/math.{type Vector, Vector}

pub type MouseEvent {
  MouseEvent(position: Vector, shift_key_active: Bool)
}

pub fn mouse_event_decoder(e) -> Result(MouseEvent, List(DecodeError)) {
  event.stop_propagation(e)

  use shift_key <- result.try(dynamic.field("shiftKey", dynamic.bool)(e))
  use position <- result.try(event.mouse_position(e))

  Ok(MouseEvent(
    position: Vector(float.round(position.0), float.round(position.1)),
    shift_key_active: shift_key,
  ))
}

pub fn keydown_event_decoder(e) -> Result(String, List(DecodeError)) {
  use key <- result.try(dynamic.field("key", dynamic.string)(e))

  Ok(key)
}
