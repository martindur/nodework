import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import nodework/node.{type NodeFunction}
import nodework/vector.{type Vector, Vector}

// type MenuItem {
//   MenuItem(label: String, identifier: String, 
// }

pub type Menu {
  Menu(pos: Vector, active: Bool, nodes: List(#(String, String)))
}

fn view_menu_item(
  item: #(String, String),
  spawn_func: fn(Dynamic) -> Result(msg, List(DecodeError)),
) -> element.Element(msg) {
  let #(text, id) = item
  html.button(
    [
      attribute.id(id),
      attribute.class("hover:bg-gray-300"),
      event.on("click", spawn_func),
    ],
    [element.text(text)],
  )
}

pub fn view_menu(
  menu: Menu,
  spawn_func: fn(Dynamic) -> Result(msg, List(DecodeError)),
) -> element.Element(msg) {
  let pos =
    "translate("
    <> int.to_string(menu.pos.x)
    <> "px, "
    <> int.to_string(menu.pos.y)
    <> "px)"

  html.div(
    case menu.active {
      True -> [
        attribute.class(
          "absolute top-0 left-0 w-[100px] h-[300px] bg-gray-200 rounded shadow",
        ),
        attribute.style([#("transform", pos)]),
      ]
      False -> [attribute.class("hidden")]
    },
    [
      html.div(
        [attribute.class("flex flex-col p-2 gap-1")],
        menu.nodes
          |> list.map(fn(item) { view_menu_item(item, spawn_func) }),
      ),
    ],
  )
}

pub fn new(nodes: List(NodeFunction)) -> Menu {
  nodes
  |> list.map(fn(node) {
    #(string.capitalise(node.label), string.lowercase(node.label))
  })
  |> list.prepend(#("Output", "output"))
  |> fn(nodes) { Menu(Vector(0, 0), False, nodes: nodes) }
}
