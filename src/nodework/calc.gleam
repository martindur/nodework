import gleam/dict
import gleam/dynamic
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
import nodework/model.{type Model, Model}
import nodework/node.{type Node}

fn nodes_to_vertices(nodes: List(Node)) -> List(#(VertexId, Vertex)) {
  nodes
  |> map(fn(n) { #(n.id, Vertex(n.id, string.lowercase(n.name), dict.new())) })
}

fn conns_to_edges(conns: List(Conn)) -> List(Edge) {
  conns
  |> map(fn(c) {
    Edge(c.source_node_id, c.target_node_id, c.target_input_value)
  })
}

fn filter_conns_by_edges(conns: List(Conn), edges: List(Edge)) -> List(Conn) {
  let edge_source_ids = map(edges, fn(e) { e.from })

  conns
  |> filter(fn(c) { contains(edge_source_ids, c.source_node_id) })
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

fn eval_graph(verts: List(Vertex), model: Model) -> Model {
  verts
  |> list.fold(dict.new(), fn(evaluated, vert) {
    case dict.get(model.library, vert.value) {
      Error(Nil) -> dict.insert(evaluated, vert.id, dynamic.from(0))
      Ok(nodefunc) -> {

        let inputs =
          vert.inputs
          |> dict.to_list
          |> map(fn(keypair) {
            let #(ref, key) = keypair
            case dict.get(evaluated, key) {
              Error(Nil) -> #(ref, dynamic.from(0))
              Ok(val) -> #(ref, val)
            }
          })
          |> dict.from_list

        inputs
        |> nodefunc.output
        |> fn(val) { dict.insert(evaluated, vert.id, val) }
      }
    }
  })
  |> dict.get("node.output")
  |> fn(res) {
    case res {
      Ok(output) -> output
      Error(Nil) -> dynamic.from(0)
    }
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
        []
      }
    }
  }
  |> eval_graph(model)
}
