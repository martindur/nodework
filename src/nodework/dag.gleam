import gleam/dict.{type Dict}
import gleam/io
import gleam/list.{contains, filter, fold, map, partition}
import gleam/pair
import gleam/queue.{type Queue}
import gleam/result

import util/debug.{labeled_debug}

pub type VertexId =
  String

pub type Vertex {
  Vertex(id: VertexId, value: String, inputs: List(String))
}

pub type Edge {
  Edge(from: VertexId, to: VertexId)
}

pub type Graph {
  Graph(verts: Dict(VertexId, Vertex), edges: List(Edge))
}

pub fn new() -> Graph {
  Graph(dict.new(), [])
}

pub fn test_data() -> Graph {
  ["a", "b", "c", "d", "e"]
  |> map(fn(val) { #(val, Vertex(val, val, [])) })
  |> dict.from_list
  |> fn(verts) {
    let edges = [
      Edge("a", "c"),
      Edge("b", "c"),
      Edge("c", "d"),
      Edge("b", "e"),
      Edge("d", "e"),
    ]
    Graph(verts: verts, edges: edges)
  }
  |> sync_vertex_inputs
}

pub fn sync_vertex_inputs(graph: Graph) -> Graph {
  graph.verts
  |> dict.map_values(fn(id, v) {
    graph.edges
    |> filter(fn(edge) { id == edge.to })
    |> map(fn(edge) { edge.from })
    |> fn(inputs) { Vertex(..v, inputs: inputs) }
  })
  |> fn(verts) { Graph(..graph, verts: verts) }
}

pub fn add_vertex(graph: Graph, vert: Vertex) -> Graph {
  graph.verts
  |> dict.insert(vert.id, vert)
  |> fn(verts) { Graph(..graph, verts: verts) }
}

// pub fn add_edge(graph: Graph, edge: Edge) -> Result(Graph, String) {
//   case has_cycle(graph, edge) {
//     True -> Error("Adding this edge would create a cycle")
//     False -> {
//       graph.edges
//       |> list.prepend(edge)
//       |> fn(edges) { Ok(Graph(..graph, edges: edges)) }
//     }
//   }
// }

// fn has_cycle(graph: Graph, edge: Edge) -> Bool {
//   graph.edges
//   |> list.prepend(edge)
//   |> fn(edges) { 
//   False
// }

fn sort(
  sorted: List(Vertex),
  unsorted: List(Vertex),
  edges: List(Edge),
) -> Result(List(Vertex), String) {
  let edges = prune(edges, sorted)

  unsorted
  |> partition_source_verts(edges)
  |> fn(res) {
    case res {
      #([], []) -> Ok(sorted)
      #(source, []) -> Ok(list.append(sorted, source))
      #([], _) -> Error("Cyclical relationship detected")
      #(source, rest) -> {
        let sorted = list.append(sorted, source)
        case sort(sorted, rest, edges) {
          Ok(res) -> Ok(res)
          Error(err) -> Error(err)
        }
      }
    }
  }
}

fn prune(edges: List(Edge), verts: List(Vertex)) -> List(Edge) {
  let ids = map(verts, fn(v) { v.id })
  edges
  |> partition(fn(e) { contains(ids, e.to) || contains(ids, e.from) })
  |> fn(x) { pair.second(x) }
}

fn indegree(vert: Vertex, edges: List(Edge)) -> Int {
  edges
  |> list.filter(fn(edge) { edge.to == vert.id })
  |> list.length
}

fn outdegree(vert: Vertex, edges: List(Edge)) -> Int {
  edges
  |> list.filter(fn(edge) { edge.from == vert.id })
  |> list.length
}

fn source_verts(verts: List(Vertex), edges: List(Edge)) -> List(Vertex) {
  verts
  |> list.filter(fn(v) { indegree(v, edges) == 0 })
}

fn partition_source_verts(
  verts: List(Vertex),
  edges: List(Edge),
) -> #(List(Vertex), List(Vertex)) {
  verts
  |> list.partition(fn(vert) { indegree(vert, edges) == 0 })
}

fn sink_verts(verts: List(Vertex), edges: List(Edge)) -> List(Vertex) {
  verts
  |> list.filter(fn(v) { outdegree(v, edges) == 0 })
}

pub fn topological_sort(graph: Graph) -> Result(List(Vertex), String) {
  sort([], graph.verts |> dict.to_list |> map(pair.second), graph.edges)
}
