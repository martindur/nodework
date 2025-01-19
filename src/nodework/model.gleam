import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import gleam/set.{type Set}
import nodework/util/random

import nodework/conn.{type Conn, type ConnID}
import nodework/dag.{type DAG}
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

pub type UIGraph {
  UIGraph(
    id: UIGraphID,
    nodes: Dict(UINodeID, UINode),
    connections: List(Conn),
    title: String,
  )
}

pub fn new_graph() {
  let id = random.generate_random_id("graph")
  UIGraph(id, dict.new(), [], "Untitled")
}

pub type UIGraphID =
  String

pub type Collection =
  Dict(UIGraphID, UIGraph)

pub type Model {
  Model(
    lib: NodeLibrary,
    collection: Collection,
    graph: UIGraph,
    nodes_selected: Set(UINodeID),
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector,
    last_clicked_point: Vector,
    mouse_down: Bool,
    mode: GraphMode,
    output: Dynamic,
    dag: DAG,
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
  GraphSaveCollection
  GraphLoadGraph(UIGraphID)
  GraphEnableShortcuts(Bool)
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
  UserChangedGraphTitle(String)
  UserClickedCollectionItem(UIGraphID)
  UserClickedNewGraph
}
