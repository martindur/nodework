import gleam/set.{type Set}
import gleam/dict.{type Dict}
import graph/node.{type Node, type NodeId}
import graph/conn.{type Conn}
import graph/vector.{type Vector}
import graph/viewbox.{type ViewBox, type GraphMode}
import graph/navigator.{type Navigator}

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
