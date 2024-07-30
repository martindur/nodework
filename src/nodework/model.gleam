import nodework/lib.{type NodeLibrary, type LibraryMenu}
import nodework/math.{type Vector}
import nodework/draw/viewbox.{type ViewBox}

pub type Model {
  Model(
    lib: NodeLibrary,
    menu: LibraryMenu,
    window_resolution: Vector,
    viewbox: ViewBox,
    cursor: Vector
  )
}
