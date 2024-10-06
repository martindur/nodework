import gleam/io
import gleam/pair
import gleam/result
import gleam/dynamic.{field, list}
import gleam/json.{
  type Json, bool, int, object, preprocessed_array, string, to_string, type DecodeError
}
import gleam/list
import gleam/dict.{type Dict}
import nodework/math.{type Vector, Vector}

import nodework/node.{type UINode, UINode, type UINodeInput, UINodeInput, type UINodeOutput, UINodeOutput}
import nodework/conn.{type Conn, Conn}
import nodework/model.{type Model, Model, type GraphTitle, GraphTitle, ReadMode}

pub type StoredGraph {
  StoredGraph(nodes: List(UINode), connections: List(Conn), title: String)
}

@external(javascript, "../../storage.ffi.mjs", "saveToLocalStorage")
pub fn save_to_storage(key: String, data: String) -> Nil

@external(javascript, "../../storage.ffi.mjs", "getFromLocalStorage")
pub fn get_from_storage(key: String) -> String

fn encode_ui_node_input(input: UINodeInput) -> Json {
  [
    #("id", string(input.id)),
    #("position", encode_vector(input.position)),
    #("label", string(input.label)),
    #("hovered", bool(input.hovered)),
  ]
  |> object
}

fn encode_ui_node_output(output: UINodeOutput) -> Json {
  [
    #("id", string(output.id)),
    #("position", encode_vector(output.position)),
    #("hovered", bool(output.hovered)),
  ]
  |> object
}

fn encode_vector(vec: Vector) -> Json {
  [#("x", int(vec.x)), #("y", int(vec.y))]
  |> object
}

fn encode_ui_node(n: UINode) -> Json {
  [
    #("label", string(n.label)),
    #("key", string(n.key)),
    #("id", string(n.id)),
    #("inputs", preprocessed_array(list.map(n.inputs, encode_ui_node_input))),
    #("output", encode_ui_node_output(n.output)),
    #("position", encode_vector(n.position)),
    #("offset", encode_vector(n.offset)),
  ]
  |> object
}

fn encode_conn(c: Conn) -> Json {
  [
    #("id", string(c.id)),
    #("p0", encode_vector(c.p0)),
    #("p1", encode_vector(c.p1)),
    #("from", string(c.from)),
    #("to", string(c.to)),
    #("value", string(c.value)),
    #("dragged", bool(c.dragged))
  ]
  |> object
}

fn decode_ui_nodes(json_string: String) -> Result(List(UINode), DecodeError) {
  let vec_decoder = dynamic.decode2(
    Vector,
    field("x", dynamic.int),
    field("y", dynamic.int)
  )

  let input_decoder = dynamic.decode4(
    UINodeInput,
    field("id", dynamic.string),
    field("position", vec_decoder),
    field("label", dynamic.string),
    field("hovered", dynamic.bool)
  )

  let output_decoder = dynamic.decode3(
    UINodeOutput,
    field("id", dynamic.string),
    field("position", vec_decoder),
    field("hovered", dynamic.bool)
  )

  let node_decoder = dynamic.decode7(
    UINode,
    field("label", dynamic.string),
    field("key", dynamic.string),
    field("id", dynamic.string),
    field("inputs", list(input_decoder)),
    field("output", output_decoder),
    field("position", vec_decoder),
    field("offset", vec_decoder)
  )

  let decoder = list(node_decoder)

  json.decode(from: json_string, using: decoder)
}

pub fn nodes_to_json(nodes: List(UINode)) -> String {
  nodes
  |> list.map(encode_ui_node)
  |> preprocessed_array
  |> to_string
}

pub fn json_to_nodes(json_string: String) -> Dict(String, UINode) {
  json_string
  |> decode_ui_nodes
  |> fn(res) {
    case res {
      Ok(nodes) -> nodes
      Error(_) -> []
    }
  }
  |> list.map(fn(node) {
    #(node.id, node)
  })
  |> dict.from_list
}

pub fn graph_to_json(model: Model) -> String {
  let nodes =
    model.nodes
    |> dict.to_list
    |> list.map(pair.second)
    |> list.map(encode_ui_node)
    |> preprocessed_array

  let connections =
    model.connections
    |> list.map(encode_conn)
    |> preprocessed_array

  [
    #("title", string(model.title.text)),
    #("nodes", nodes),
    #("connections", connections)
  ]
  |> object
  |> to_string
}

pub fn json_to_graph(model: Model, json_string: String) -> Model {
  let vec_decoder = dynamic.decode2(
    Vector,
    field("x", dynamic.int),
    field("y", dynamic.int)
  )

  let node_input_decoder = dynamic.decode4(
    UINodeInput,
    field("id", dynamic.string),
    field("position", vec_decoder),
    field("label", dynamic.string),
    field("hovered", dynamic.bool)
  )

  let node_output_decoder = dynamic.decode3(
    UINodeOutput,
    field("id", dynamic.string),
    field("position", vec_decoder),
    field("hovered", dynamic.bool)
  )

  let node_decoder = dynamic.decode7(
    UINode,
    field("label", dynamic.string),
    field("key", dynamic.string),
    field("id", dynamic.string),
    field("inputs", list(node_input_decoder)),
    field("output", node_output_decoder),
    field("position", vec_decoder),
    field("offset", vec_decoder)
  )

  let conn_decoder = dynamic.decode7(
    Conn,
    field("id", dynamic.string),
    field("p0", vec_decoder),
    field("p1", vec_decoder),
    field("from", dynamic.string),
    field("to", dynamic.string),
    field("value", dynamic.string),
    field("dragged", dynamic.bool)
  )

  let node_list_decoder = list(node_decoder)
  let conn_list_decoder = list(conn_decoder)


  let decoder = dynamic.decode3(
    StoredGraph,
    field("nodes", node_list_decoder),
    field("connections", conn_list_decoder),
    field("title", dynamic.string)
  )

  case json.decode(from: json_string, using: decoder) {
    Error(_) -> model
    Ok(graph) -> 
      Model(
        ..model,
        title: GraphTitle(text: graph.title, mode: ReadMode),
        nodes: graph.nodes |> list.map(fn(n) { #(n.id, n) }) |> dict.from_list,
        connections: graph.connections
    )
  }
}
