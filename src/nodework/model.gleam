import gleam/dict.{type Dict}

import nodework/decoder.{type MouseEvent}
import nodework/draw/viewbox.{type ViewBox}
import nodework/lib.{type LibraryMenu, type NodeLibrary}
import nodework/math.{type Vector}
import nodework/node.{type UINode, type UINodeID, type UINodeOutputID}

pub type Model {
  Model(
    lib: NodeLibrary,
    nodes: Dict(UINodeID, UINode),
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector,
    last_clicked_point: Vector,
  )
}

pub type Msg {
  GraphResizeViewBox(Vector)
  GraphOpenMenu
  GraphCloseMenu
  GraphSpawnNode(String)
  GraphSetDragMode
  GraphClearSelection
  UserPressedKey(String)
  UserClickedGraph(MouseEvent)
  UserMovedMouse(Vector)
  UserClickedNode(UINodeID, MouseEvent)
  UserUnclickedNode(UINodeID)
  UserClickedNodeOutput(UINodeID, Vector)
  UserHoverNodeOutput(UINodeOutputID)
  UserUnhoverNodeOutputs
}
