import gleam/dict.{type Dict}
import gleam/list.{contains, filter, map, partition}
import gleam/pair

pub type VertexId =
  String

/// A Vertex is similar to a 'node', but the internal type used to do topological sort
/// id: Should be the same as its Node cousin
/// value: holds an identifier to the type of node, e.g. 'int.add' or 'string.capitalise'
/// inputs: a dict of input keys to node ids (to figure out which node's output is connected to which input)
pub type Vertex {
  Vertex(id: VertexId, value: String, inputs: Dict(String, String))
}

pub type Edge {
  Edge(from: VertexId, to: VertexId, input: String)
}

pub type DAG {
  DAG(verts: Dict(VertexId, Vertex), edges: List(Edge))
}

pub fn new() -> DAG {
  DAG(dict.new(), [])
}

pub fn test_data() -> DAG {
  ["a", "b", "c", "d", "e"]
  |> map(fn(val) { #(val, Vertex(val, val, dict.new())) })
  |> dict.from_list
  |> fn(verts) {
    let edges = [
      Edge("a", "c", ""),
      Edge("b", "c", ""),
      Edge("c", "d", ""),
      Edge("b", "e", ""),
      Edge("d", "e", ""),
    ]
    DAG(verts: verts, edges: edges)
  }
  |> sync_vertex_inputs
}

pub fn sync_vertex_inputs(dag: DAG) -> DAG {
  dag.verts
  |> dict.map_values(fn(id, vertex) {
    dag.edges
    |> filter(fn(edge) { id == edge.to })
    |> map(fn(edge) { #(edge.input, edge.from) })
    |> dict.from_list
    |> fn(inputs) { Vertex(..vertex, inputs: inputs) }
  })
  |> fn(verts) { DAG(..dag, verts: verts) }
}

pub fn add_vertex(dag: DAG, vert: Vertex) -> DAG {
  dag.verts
  |> dict.insert(vert.id, vert)
  |> fn(verts) { DAG(..dag, verts: verts) }
}

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

fn partition_source_verts(
  verts: List(Vertex),
  edges: List(Edge),
) -> #(List(Vertex), List(Vertex)) {
  verts
  |> list.partition(fn(vert) { indegree(vert, edges) == 0 })
}

pub fn source_verts(verts: List(Vertex), edges: List(Edge)) -> List(Vertex) {
  verts
  |> list.filter(fn(v) { indegree(v, edges) == 0 })
}

pub fn sink_verts(verts: List(Vertex), edges: List(Edge)) -> List(Vertex) {
  verts
  |> list.filter(fn(v) { outdegree(v, edges) == 0 })
}

pub fn topological_sort(dag: DAG) -> Result(List(Vertex), String) {
  sort([], dag.verts |> dict.to_list |> map(pair.second), dag.edges)
}
