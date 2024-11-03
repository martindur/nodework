import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/set.{type Set}

import nodework/conn.{type Conn, type ConnID}
import nodework/dag.{type Graph}
import nodework/decoder.{type MouseEvent}
import nodework/draw/viewbox.{type ViewBox}
import nodework/lib.{type LibraryMenu, type NodeLibrary}
import nodework/math.{type Vector}
import nodework/node.{
  type UINode, type UINodeID, type UINodeInputID, type UINodeOutputID,
}

pub type GraphMode {
  DragMode
  NormalMode
}

pub type EditMode {
  ReadMode
  WriteMode
}

pub type GraphTitle {
  GraphTitle(text: String, mode: EditMode)
}

pub type UIGraph {
  UIGraph(
    id: UIGraphID,
    nodes: Dict(UINodeID, UINode),
    connections: List(Conn),
    title: GraphTitle,
  )
}

pub type UIGraphID =
  String

pub type Collection = List(#(UIGraphID, String))

pub type Model {
  Model(
    lib: NodeLibrary,
    collection: Collection,
    active_graph: UIGraphID,
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
    graph: Graph,
    title: GraphTitle,
    shortcuts_active: Bool,
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
  GraphSaveGraph
  GraphLoadGraph(UIGraphID)
  GraphSetTitleToReadMode
  UserPressedKey(String)
  UserMovedMouse(Vector)
  UserScrolled(Float)
  UserClickedGraph(MouseEvent)
  UserClickedGraphTitle
  UserUnclicked
  UserClickedNode(UINodeID, MouseEvent)
  UserUnclickedNode
  UserClickedNodeOutput(UINodeID, Vector)
  UserHoverNodeOutput(UINodeOutputID)
  UserUnhoverNodeOutputs
  UserHoverNodeInput(UINodeInputID)
  UserUnhoverNodeInputs
  UserClickedConn(ConnID, MouseEvent)
  UserChangedGraphTitle(String)
  UserClickedCollectionItem(UIGraphID)
  UserClickedNewGraph
}
