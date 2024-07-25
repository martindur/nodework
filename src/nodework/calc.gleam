import gleam/io
import gleam/dict
import gleam/list.{map}
import gleam/pair
import nodework/dag.{type Vertex, type VertexId, Graph, Vertex}
import nodework/model.{type Model, Model}
import nodework/node.{type Node}

fn nodes_to_vertices(nodes: List(Node)) -> List(#(VertexId, Vertex)) {
  nodes
  |> map(fn(n) { #(n.id, Vertex(n.id, n.name)) })
}

pub fn update_nodes(model: Model) -> Model {
  model.nodes
  |> dict.to_list
  |> map(pair.second)
  |> nodes_to_vertices
  |> dict.from_list
  |> fn(verts) { Graph(..model.graph, verts: verts) }
  |> fn(graph) { Model(..model, graph: graph) }
}

pub fn recalc_graph(model: Model) -> Model {
  model.graph
  |> dag.topological_sort
  |> fn(res: Result(List(Vertex), String)) {
    case res {
      Ok(verts) -> {
        io.debug(verts)
        model
      }
      Error(msg) -> {
        io.debug(msg)
        model
      }
    }
  }
}
