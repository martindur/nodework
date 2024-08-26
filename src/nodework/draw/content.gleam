import gleam/dynamic.{type DecodeError}
import gleam/int
import gleam/list.{map}
import gleam/result
import gleam/set.{type Set}

import lustre/attribute.{attribute as attr}
import lustre/element.{type Element}
import lustre/element/svg
import lustre/event

import nodework/decoder.{mouse_event_decoder}
import nodework/math
import nodework/model.{
  type Msg, UserClickedNode, UserClickedNodeOutput, UserHoverNodeOutput,
  UserUnclickedNode, UserUnhoverNodeOutputs, UserHoverNodeInput, UserUnhoverNodeInputs, UserClickedConn
}
import nodework/conn.{type Conn}
import nodework/node.{
  type UINode, type UINodeID, type UINodeInput, type UINodeOutput,
}

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
          event.on_mouse_up(UserUnclickedNode),
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
        view_node_output(n.output, n.id),
      ],
      list.map(n.inputs, fn(input) { view_node_input(input) }),
    ]),
  )
}

fn view_node_input(input: UINodeInput) -> element.Element(Msg) {
  svg.g(
    [attr("transform", input.position |> math.vec_to_html(math.Translate))],
    [
      svg.circle([
        attr("cx", "0"),
        attr("cy", "0"),
        attr("r", "10"),
        attr("fill", "currentColor"),
        attr("stroke", "black"),
        case input.hovered {
          True -> attr("stroke-width", "3")
          False -> attr("stroke-width", "0")
        },
        attribute.class("text-gray-500"),
        attribute.id(input.id),
        event.on_mouse_enter(UserHoverNodeInput(input.id)),
        event.on_mouse_leave(UserUnhoverNodeInputs),
      ]),
      svg.text(
        [
          attr("x", "16"),
          attr("y", "0"),
          attr("font-size", "16"),
          attr("dominant-baseline", "middle"),
          attr("fill", "currentColor"),
          attribute.class("text-gray-900"),
        ],
        input.label,
      ),
    ],
  )
}

fn view_node_output(
  output: UINodeOutput,
  node_id: UINodeID,
) -> element.Element(Msg) {
  // TODO: Consider having an output node type, as this becomes quite hidden. It's much easier at the moment though!
  case node_id == "node.output" {
    False -> {
      svg.g(
        [attr("transform", output.position |> math.vec_to_html(math.Translate))],
        [
          svg.circle([
            attr("cx", "0"),
            attr("cy", "0"),
            attr("r", "10"),
            attr("fill", "currentColor"),
            attr("stroke", "black"),
            case output.hovered {
              True -> attr("stroke-width", "3")
              False -> attr("stroke-width", "0")
            },
            attribute.class("text-gray-500"),
            event.on_mouse_down(UserClickedNodeOutput(node_id, output.position)),
            event.on_mouse_enter(UserHoverNodeOutput(output.id)),
            event.on_mouse_leave(UserUnhoverNodeOutputs),
          ]),
        ],
      )
    }
    True -> element.none()
  }
}

pub fn view_connection(c: Conn) -> element.Element(Msg) {
  let mousedown = fn(e) -> Result(Msg, List(DecodeError)) {
    use decoded_event <- result.try(mouse_event_decoder(e))

    Ok(UserClickedConn(c.id, decoded_event))
  }

  svg.line([
    case c.dragged {
      True -> attribute.class("text-gray-500")
      False -> attribute.class("text-gray-500 hover:text-indigo-500")
    },
    attr("stroke", "currentColor"),
    attr("stroke-width", "10"),
    attr("stroke-linecap", "round"),
    attr("stroke-dasharray", "12,12"),
    event.on("mousedown", mousedown),
    ..conn.to_attributes(c)
  ])
}
