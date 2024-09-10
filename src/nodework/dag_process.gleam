import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/list.{contains, filter, map}
import gleam/pair
import gleam/result
import gleam/string
import nodework/conn.{type Conn}
import nodework/dag.{
  type Edge, type Graph, type Vertex, type VertexId, Edge, Graph, Vertex,
}
import nodework/model.{type Model, Model}
import nodework/node.{type UINode, IntNode, StringNode, IntToStringNode}

fn nodes_to_vertices(nodes: List(UINode)) -> List(#(VertexId, Vertex)) {
  nodes
  |> map(fn(n) { #(n.id, Vertex(n.id, string.lowercase(n.key), dict.new())) })
}

fn conns_to_edges(conns: List(Conn)) -> List(Edge) {
  conns
  |> map(fn(c) {
    let assert [source_node_id, target_node_id] =
      node.extract_node_ids([c.from, c.to])
    Edge(source_node_id, target_node_id, c.value)
  })
}

fn filter_conns_by_edges(conns: List(Conn), edges: List(Edge)) -> List(Conn) {
  let edge_source_ids = map(edges, fn(e) { e.from })

  conns
  |> filter(fn(c) { contains(edge_source_ids, node.extract_node_id(c.from)) })
}

pub fn sync_verts(model: Model) -> Model {
  model.nodes
  |> dict.to_list
  |> map(pair.second)
  |> nodes_to_vertices
  |> dict.from_list
  |> fn(verts) { Graph(..model.graph, verts: verts) }
  |> fn(graph) { Model(..model, graph: graph) }
}

pub fn sync_edges(model: Model) -> Model {
  model.connections
  |> conns_to_edges
  |> fn(edges) { Graph(..model.graph, edges: edges) }
  |> fn(graph) {
    case dag.topological_sort(graph) {
      Ok(_) -> Model(..model, graph: graph)
      Error(_) -> {
        filter_conns_by_edges(model.connections, model.graph.edges)
        |> fn(conns) { Model(..model, graph: model.graph, connections: conns) }
      }
    }
  }
}

fn eval_vertex_inputs(
  inputs: Dict(String, String),
  lookup: Dict(String, Dynamic),
) -> List(#(String, Dynamic)) {
  inputs
  |> dict.to_list
  |> map(fn(input_data) {
    let #(input_name, node_id) = input_data

    // find the output value of the given node (this should generally always be present, due to topological sort)
    case dict.get(lookup, node_id) {
      Ok(value) -> #(input_name, value)
      Error(Nil) -> #(input_name, dynamic.from(""))
    }
  })
}

fn typed_inputs(
  inputs: List(#(String, Dynamic)),
  decoder: fn(Dynamic) -> a,
) -> List(#(String, a)) {
  inputs
  |> map(pair.map_second(_, decoder))
}

fn eval_graph(verts: List(Vertex), model: Model) -> Model {
  let int_decoder = fn(x) { result.unwrap(dynamic.int(x), 0) }
  let string_decoder = fn(x) { result.unwrap(dynamic.string(x), "") }

  verts
  // for each vert
  // 1. fetch the node associated with its value
  // 2. convert any vertex inputs into values from previous vertices (This is a guaranteed order after topological sort)
  // 3. run the associated output func from the fetched node, feeding it the inputs as a dict
  // 4. finally, lookup the "output" key in the derived dict to get the result of the output node, and add it to model
  |> list.fold(dict.new(), fn(lookup_evaluated, vertex) {
    let inputs = eval_vertex_inputs(vertex.inputs, lookup_evaluated)

    case dict.get(model.lib.nodes, vertex.value) {
      Ok(IntNode(_, _, _, func)) -> {
        inputs
        |> typed_inputs(int_decoder)
        |> dict.from_list
        |> func
        |> dynamic.from
      }
      Ok(StringNode(_, _, _, func)) -> {
        inputs
        |> typed_inputs(string_decoder)
        |> dict.from_list
        |> func
        |> dynamic.from
      }
      Ok(IntToStringNode(_, _, _, func)) -> {
        inputs
        |> typed_inputs(int_decoder)
        |> dict.from_list
        |> func
        |> dynamic.from
      }
      Error(Nil) -> dynamic.from("")
    }
    |> dict.insert(lookup_evaluated, vertex.id, _)
  })
  |> fn(lookup_evaluated) {
    dict.get(lookup_evaluated, "node-output")
    |> result.unwrap(dynamic.from("No output"))
  }
  |> fn(output) { Model(..model, output: output) }
}

pub fn recalc_graph(model: Model) -> Model {
  model.graph
  |> dag.sync_vertex_inputs
  |> dag.topological_sort
  |> fn(res: Result(List(Vertex), String)) {
    case res {
      Ok(verts) -> verts
      Error(msg) -> {
        io.debug(msg)
        []
      }
    }
  }
  |> eval_graph(model)
}
