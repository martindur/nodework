import gleam/dynamic.{type DecodeError}
import gleam/result
import gleam/set.{type Set}
import gleam/int
import gleam/list.{map}

import lustre/attribute.{attribute as attr}
import lustre/element.{type Element}
import lustre/element/svg
import lustre/event

import nodework/model.{type Msg, UserClickedNode, UserUnclickedNode}
import nodework/node.{type UINode, type UINodeID}
import nodework/decoder.{mouse_event_decoder}

fn translate(x: Int, y: Int) -> String {
  [x, y]
  |> map(int.to_string)
  |> fn(val) {
    let assert [a, b] = val

    "translate(" <> a <> "," <> b <> ")"
  }
}

pub fn view_node(n: UINode, selection: Set(UINodeID)) -> Element(Msg) {
  let node_selected_class = case set.contains(selection, n.id) {
    True -> attribute.class("text-gray-300 stroke-gray-400")
    False -> attribute.class("text-gray-300 stroke-gray-300")
  }

  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedNode(n.id, decoded_event))
  }

  svg.g(
    [
      attribute.id("g-" <> n.id),
      attr("transform", translate(n.position.x, n.position.y)),
      attribute.class("select-none"),
    ],
   list.concat([
      [
        svg.rect([
          attribute.id(n.id),
          attr("width", "200"),
          attr("height", "150"),
          attr("rx", "25"),
          attr("ry", "25"),
          attr("fill", "currentColor"),
          attr("stroke", "currentColor"),
          attr("stroke-width", "2"),
          node_selected_class,
          event.on("mousedown", mousedown),
          event.on_mouse_up(UserUnclickedNode(n.id)),
        ]),
        svg.text(
          [
            attr("x", "20"),
            attr("y", "24"),
            attr("font-size", "16"),
            attr("fill", "currentColor"),
            attribute.class("text-gray-900"),
          ],
          n.label,
        ),
        // view_node_output(n),
      ],
      // list.map(n.inputs, fn(input) { view_node_input(input) }),
    ]),
  )
}


// fn view_node_input(input: NodeInput) -> element.Element(Msg) {
//   let id = nd.input_id(input)
//   let label = nd.input_label(input)
//   let hovered = nd.input_hovered(input)

//   svg.g(
//     [
//       attr(
//         "transform",
//         nd.input_position(input) |> vector.to_html(vector.Translate),
//       ),
//     ],
//     [
//       svg.circle([
//         attr("cx", "0"),
//         attr("cy", "0"),
//         attr("r", "10"),
//         attr("fill", "currentColor"),
//         attr("stroke", "black"),
//         case hovered {
//           True -> attr("stroke-width", "3")
//           False -> attr("stroke-width", "0")
//         },
//         attribute.class("text-gray-500"),
//         attribute.id(id),
//         event.on_mouse_enter(UserHoverNodeInput(id)),
//         event.on_mouse_leave(UserUnhoverNodeInput),
//       ]),
//       svg.text(
//         [
//           attr("x", "16"),
//           attr("y", "0"),
//           attr("font-size", "16"),
//           attr("dominant-baseline", "middle"),
//           attr("fill", "currentColor"),
//           attribute.class("text-gray-900"),
//         ],
//         label,
//       ),
//     ],
//   )
// }

// fn view_node_output(node: Node) -> element.Element(Msg) {
//   let pos = nd.output_position(node.output)
//   let id = nd.output_id(node.output)
//   let hovered = nd.output_hovered(node.output)

//   // TODO: Consider having an output node type, as this becomes quite hidden. It's much easier at the moment though!
//   case node.id == "node.output" {
//     False -> {
//       svg.g([attr("transform", pos |> vector.to_html(vector.Translate))], [
//         svg.circle([
//           attr("cx", "0"),
//           attr("cy", "0"),
//           attr("r", "10"),
//           attr("fill", "currentColor"),
//           attr("stroke", "black"),
//           case hovered {
//             True -> attr("stroke-width", "3")
//             False -> attr("stroke-width", "0")
//           },
//           attribute.class("text-gray-500"),
//           event.on_mouse_down(UserClickedNodeOutput(node.id, pos)),
//           event.on_mouse_enter(UserHoverNodeOutput(id)),
//           event.on_mouse_leave(UserUnhoverNodeOutput),
//         ]),
//       ])
//     }
//     True -> element.none()
//   }
// }
