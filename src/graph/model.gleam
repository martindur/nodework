import gleam/dict.{type Dict}
import gleam/set.{type Set}
import graph/conn.{type Conn}
import graph/navigator.{type Navigator}
import graph/node.{type Node, type NodeId}
import graph/vector.{type Vector}
import graph/viewbox.{type GraphMode, type ViewBox}

pub type Model {
  Model(
    nodes: Dict(NodeId, Node),
    connections: List(Conn),
    nodes_selected: Set(NodeId),
    window_resolution: Vector,
    viewbox: ViewBox,
    navigator: Navigator,
    mode: GraphMode,
    last_clicked_point: Vector,
  )
}
