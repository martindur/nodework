import gleam/int
import gleam/list

import lustre
import lustre/effect
import lustre/element
import lustre/element/html

import nodework/lib.{type NodeLibrary}

pub type Model {
  Model(lib: NodeLibrary)
}

pub type Msg {
  SomeMsg
}

pub fn app() {
  lustre.application(init, update, view)
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", lib.new())

  Nil
}

fn init(node_lib: NodeLibrary) -> #(Model, effect.Effect(Msg)) {
  #(Model(node_lib), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    SomeMsg -> #(model, effect.none())
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let int_nodes = list.map(model.lib.ints, fn(n) { n.identifier})
  let string_nodes = list.map(model.lib.strings, fn(n) { n.identifier })

  let nodes = list.append(int_nodes, string_nodes)

  html.div(
    [],
    list.map(nodes, fn(node) { element.text(node) }),
  )
}
