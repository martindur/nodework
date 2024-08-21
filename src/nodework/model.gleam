import gleam/dict.{type Dict}
import gleam/set.{type Set}

import nodework/decoder.{type MouseEvent}
import nodework/draw/viewbox.{type ViewBox}
import nodework/lib.{type LibraryMenu, type NodeLibrary}
import nodework/math.{type Vector}
import nodework/node.{
  type UINode, type UINodeID, type UINodeInputID, type UINodeOutputID,
}

pub type Model {
  Model(
    lib: NodeLibrary,
    nodes: Dict(UINodeID, UINode),
    nodes_selected: Set(UINodeID),
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector,
    last_clicked_point: Vector,
    mouse_down: Bool,
  )
}

pub type Msg {
  GraphResizeViewBox(Vector)
  GraphOpenMenu
  GraphCloseMenu
  GraphSpawnNode(String)
  GraphSetDragMode
  GraphClearSelection
  GraphAddNodeToSelection(UINodeID)
  GraphSetNodeAsSelection(UINodeID)
  UserPressedKey(String)
  UserClickedGraph(MouseEvent)
  UserMovedMouse(Vector)
  UserClickedNode(UINodeID, MouseEvent)
  UserUnclickedNode
  UserClickedNodeOutput(UINodeID, Vector)
  UserHoverNodeOutput(UINodeOutputID)
  UserUnhoverNodeOutputs
  UserHoverNodeInput(UINodeInputID)
  UserUnhoverNodeInputs
}
