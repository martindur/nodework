import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/io
import gleam/list.{contains, filter, map, zip}
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import nodework/conn.{type Conn}
import nodework/dag.{
  type Edge, type Graph, type Vertex, type VertexId, Edge, Graph, Vertex,
}
import nodework/lib
import nodework/model.{type Model, Model}
import nodework/node.{type UINode, IntNode, StringNode}

fn nodes_to_vertices(nodes: List(UINode)) -> List(#(VertexId, Vertex)) {
  nodes
  |> map(fn(n) { #(n.id, Vertex(n.id, string.lowercase(n.key), dict.new())) })
}

fn conns_to_edges(conns: List(Conn)) -> List(Edge) {
  conns
  |> map(fn(c) {
    let assert [source_node_id, target_node_id] = node.extract_node_ids([c.from, c.to])
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

fn node_eval_to_values(inputs: Dict(String, String), lookup: Dict(String, Dynamic)) -> Dict(String, Dynamic) {
  inputs
  |> dict.to_list
  |> map(fn(input_data) {
    let #(key, node_id) = input_data

    case dict.get(lookup, node_id) {
      Ok(value) -> #(key, value)
      Error(Nil) -> #(key, dynamic.from(0))
    }
  })
  dict.from_list
}

fn eval_graph(verts: List(Vertex), model: Model) -> Model {
  verts
  // for each vert
  // 1. fetch the node associated with its value
  // 2. convert any vertex inputs into values from previous vertices (This is a guaranteed order after topological sort)
  // 3. run the associated output func from the fetched node, feeding it the inputs as a dict
  // 4. finally, lookup the "output" key in the derived dict to get the result of the output node, and add it to model
  |> io.debug
  |> list.fold(dict.new(), fn(lookup_evaluated, vertex) {
    let inputs =
      vertex.inputs
      |> dict.to_list
      |> map(fn(input_data) {
        let #(key, node_id) = input_data

        case dict.get(lookup_evaluated, node_id) {
          Ok(value) -> #(key, value)
          Error(Nil) -> #(key, dynamic.from(0))
        }
      })
      |> dict.from_list

    case dict.get(model.lib.nodes, vertex.id) {
      Error(Nil) -> dict.insert(lookup_evaluated, vertex.id, dynamic.from(0))
      Ok(IntNode(_, _, _, func)) -> {
        dict.insert(lookup_evaluated, vertex.id, dynamic.from(func(inputs)))
      }
    }
  })

  model
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
