import gleam/dict.{type Dict}
import gleam/dynamic.{field, list}
import gleam/int
import gleam/io
import gleam/json.{
  type DecodeError, type Json, bool, int, object, preprocessed_array, string,
  to_string,
}
import gleam/list
import gleam/pair
import gleam/result
import nodework/math.{type Vector, Vector}

import nodework/conn.{type Conn, Conn}
import nodework/model.{
  type Collection, type GraphTitle, type Model, type UIGraph, GraphTitle, Model,
  ReadMode, UIGraph,
}
import nodework/node.{
  type UINode, type UINodeInput, type UINodeOutput, UINode, UINodeInput,
  UINodeOutput,
}

pub type StoredGraph {
  StoredGraph(
    id: String,
    nodes: List(UINode),
    connections: List(Conn),
    title: String,
  )
}

@external(javascript, "../../storage.ffi.mjs", "saveToLocalStorage")
pub fn save_to_storage(key: String, data: String) -> Nil

@external(javascript, "../../storage.ffi.mjs", "getFromLocalStorage")
pub fn get_from_storage(key: String) -> String

fn ui_graph_to_stored_graph(graph: UIGraph) -> StoredGraph {
  graph.nodes
  |> dict.to_list
  |> list.map(pair.second)
  |> fn(nodes) {
    StoredGraph(
      id: graph.id,
      nodes: nodes,
      connections: graph.connections,
      title: graph.title.text,
    )
  }
}

pub fn stored_graph_to_ui_graph(graph: StoredGraph) -> UIGraph {
  graph.nodes
  |> list.map(fn(node) { #(node.id, node) })
  |> dict.from_list
  |> fn(nodes) {
    UIGraph(
      id: graph.id,
      nodes: nodes,
      connections: graph.connections,
      title: GraphTitle(graph.title, ReadMode),
    )
  }
}

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
    #("dragged", bool(c.dragged)),
  ]
  |> object
}

pub fn encode_graph(graph: UIGraph) -> Json {
  ui_graph_to_stored_graph(graph)
  |> fn(graph) {
    [
      #("id", string(graph.id)),
      #("title", string(graph.title)),
      #("nodes", nodes_to_json(graph.nodes)),
      #("connections", connections_to_json(graph.connections)),
    ]
  }
  |> object
}

fn decode_ui_nodes(json_string: String) -> Result(List(UINode), DecodeError) {
  let vec_decoder =
    dynamic.decode2(Vector, field("x", dynamic.int), field("y", dynamic.int))

  let input_decoder =
    dynamic.decode4(
      UINodeInput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("label", dynamic.string),
      field("hovered", dynamic.bool),
    )

  let output_decoder =
    dynamic.decode3(
      UINodeOutput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("hovered", dynamic.bool),
    )

  let node_decoder =
    dynamic.decode7(
      UINode,
      field("label", dynamic.string),
      field("key", dynamic.string),
      field("id", dynamic.string),
      field("inputs", list(input_decoder)),
      field("output", output_decoder),
      field("position", vec_decoder),
      field("offset", vec_decoder),
    )

  let decoder = list(node_decoder)

  json.decode(from: json_string, using: decoder)
}

pub fn nodes_to_json(nodes: List(UINode)) -> Json {
  nodes
  |> list.map(encode_ui_node)
  |> preprocessed_array
}

pub fn connections_to_json(conns: List(Conn)) -> Json {
  conns
  |> list.map(encode_conn)
  |> preprocessed_array
}

pub fn graphs_to_json(collection: Collection) -> Json {
  collection
  |> dict.to_list
  |> list.map(pair.second)
  |> list.map(encode_graph)
  |> preprocessed_array
}

pub fn json_to_graph_collection(json_string: String) -> Collection {
  let vec_decoder =
    dynamic.decode2(Vector, field("x", dynamic.int), field("y", dynamic.int))

  let node_input_decoder =
    dynamic.decode4(
      UINodeInput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("label", dynamic.string),
      field("hovered", dynamic.bool),
    )

  let node_output_decoder =
    dynamic.decode3(
      UINodeOutput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("hovered", dynamic.bool),
    )

  let node_decoder =
    dynamic.decode7(
      UINode,
      field("label", dynamic.string),
      field("key", dynamic.string),
      field("id", dynamic.string),
      field("inputs", list(node_input_decoder)),
      field("output", node_output_decoder),
      field("position", vec_decoder),
      field("offset", vec_decoder),
    )

  let conn_decoder =
    dynamic.decode7(
      Conn,
      field("id", dynamic.string),
      field("p0", vec_decoder),
      field("p1", vec_decoder),
      field("from", dynamic.string),
      field("to", dynamic.string),
      field("value", dynamic.string),
      field("dragged", dynamic.bool),
    )

  let node_list_decoder = list(node_decoder)
  let conn_list_decoder = list(conn_decoder)

  let graph_decoder =
    dynamic.decode4(
      StoredGraph,
      field("id", dynamic.string),
      field("nodes", node_list_decoder),
      field("connections", conn_list_decoder),
      field("title", dynamic.string),
    )

  let collection_decoder = list(graph_decoder)

  case json.decode(from: json_string, using: collection_decoder) {
    Error(_) -> dict.new()
    Ok(graphs) -> {
      graphs
      |> list.map(stored_graph_to_ui_graph)
      |> list.map(fn(graph) { #(graph.id, graph) })
      |> dict.from_list
    }
  }
}

pub fn load_graph(json_string: String) -> Result(StoredGraph, Nil) {
  let vec_decoder =
    dynamic.decode2(Vector, field("x", dynamic.int), field("y", dynamic.int))

  let node_input_decoder =
    dynamic.decode4(
      UINodeInput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("label", dynamic.string),
      field("hovered", dynamic.bool),
    )

  let node_output_decoder =
    dynamic.decode3(
      UINodeOutput,
      field("id", dynamic.string),
      field("position", vec_decoder),
      field("hovered", dynamic.bool),
    )

  let node_decoder =
    dynamic.decode7(
      UINode,
      field("label", dynamic.string),
      field("key", dynamic.string),
      field("id", dynamic.string),
      field("inputs", list(node_input_decoder)),
      field("output", node_output_decoder),
      field("position", vec_decoder),
      field("offset", vec_decoder),
    )

  let conn_decoder =
    dynamic.decode7(
      Conn,
      field("id", dynamic.string),
      field("p0", vec_decoder),
      field("p1", vec_decoder),
      field("from", dynamic.string),
      field("to", dynamic.string),
      field("value", dynamic.string),
      field("dragged", dynamic.bool),
    )

  let node_list_decoder = list(node_decoder)
  let conn_list_decoder = list(conn_decoder)

  let decoder =
    dynamic.decode4(
      StoredGraph,
      field("id", dynamic.string),
      field("nodes", node_list_decoder),
      field("connections", conn_list_decoder),
      field("title", dynamic.string),
    )

  case json.decode(from: json_string, using: decoder) {
    Error(_) -> Error(Nil)
    Ok(graph) ->
      Ok(StoredGraph(graph.id, graph.nodes, graph.connections, graph.title))
  }
}

pub fn collection_to_json_string(model: Model) -> String {
  model.collection
  |> dict.map_values(fn(graph_id, graph) {
    case model.graph.id == graph_id {
      True -> model.graph
      False -> graph
    }
  })
  |> graphs_to_json
  |> to_string
}

pub fn load_collection() -> Collection {
  case get_from_storage("nodework_graph_collection") {
    "" -> dict.new()
    json_collection -> json_to_graph_collection(json_collection)
  }
}
