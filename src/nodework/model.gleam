import gleam/dict.{type Dict}
import gleam/set.{type Set}
import gleam/dynamic.{type Dynamic}

import nodework/decoder.{type MouseEvent}
import nodework/draw/viewbox.{type ViewBox}
import nodework/lib.{type LibraryMenu, type NodeLibrary}
import nodework/math.{type Vector}
import nodework/conn.{type Conn, type ConnID}
import nodework/node.{
  type UINode, type UINodeID, type UINodeInputID, type UINodeOutputID,
}
import nodework/dag.{type Graph}

pub type GraphMode {
  DragMode
  NormalMode
}

pub type Model {
  Model(
    lib: NodeLibrary,
    nodes: Dict(UINodeID, UINode),
    connections: List(Conn),
    nodes_selected: Set(UINodeID),
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector,
    last_clicked_point: Vector,
    mouse_down: Bool,
    mode: GraphMode,
    output: Dynamic,
    graph: Graph
  )
}

pub type Msg {
  GraphResizeViewBox(Vector)
  GraphOpenMenu
  GraphCloseMenu
  GraphSpawnNode(String)
  GraphSetMode(GraphMode)
  GraphClearSelection
  GraphAddNodeToSelection(UINodeID)
  GraphSetNodeAsSelection(UINodeID)
  GraphDeleteSelectedUINodes
  GraphChangedConnections
  UserPressedKey(String)
  UserMovedMouse(Vector)
  UserScrolled(Float)
  UserClickedGraph(MouseEvent)
  UserUnclicked
  UserClickedNode(UINodeID, MouseEvent)
  UserUnclickedNode
  UserClickedNodeOutput(UINodeID, Vector)
  UserHoverNodeOutput(UINodeOutputID)
  UserUnhoverNodeOutputs
  UserHoverNodeInput(UINodeInputID)
  UserUnhoverNodeInputs
  UserClickedConn(ConnID, MouseEvent)
}
