import nodework/draw/viewbox.{type ViewBox}
import nodework/lib.{type LibraryMenu, type NodeLibrary}
import nodework/math.{type Vector}
import nodework/decoder.{type MouseEvent}

pub type Model {
  Model(
    lib: NodeLibrary,
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector,
    last_clicked_point: Vector
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
}
