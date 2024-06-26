import gleam/list
import gleeunit/should
import util/list.{unique_by} as _list

pub type Foo {
  Foo(bar: Int, baz: String)
}

pub fn unique_by__test() {
  let foos = [Foo(0, "bob"), Foo(1, "dad"), Foo(0, "joe")]

  foos
  |> unique_by(fn(x: Foo) { x.bar })
  |> list.length
  |> should.equal(2)
}
