import gleam/int
import gleam/list.{map}

pub fn translate(x: Int, y: Int) -> String {
  [x, y]
  |> map(int.to_string)
  |> fn(val) {
    let assert [a, b] = val

    "translate(" <> a <> "," <> b <> ")"
  }
}
