import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/set.{type Set}
import nodework/conn.{type Conn}
import nodework/dag.{type Graph}
import nodework/menu.{type Menu}
import nodework/navigator.{type Navigator}
import nodework/node.{type Node, type NodeFunction, type NodeId}
import nodework/vector.{type Vector}
import nodework/viewbox.{type GraphMode, type ViewBox}

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
    menu: Menu,
    library: Dict(String, NodeFunction),
    graph: Graph,
    output: Dynamic,
  )
}
