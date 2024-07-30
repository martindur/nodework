import lustre/effect.{type Effect}
import nodework/draw/viewbox
import nodework/handler.{none_effect_wrapper}
import nodework/lib.{LibraryMenu}
import nodework/math.{type Vector}
import nodework/model.{type Model, Model}

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

pub fn spawn_node(model: Model, identifier: String) -> #(Model, Effect(msg)) {
  model
  |> none_effect_wrapper
}
