import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list.{map}
import gleam/result

import lustre/attribute.{type Attribute, attribute as attr}

pub fn translate(x: Int, y: Int) -> String {
  [x, y]
  |> map(int.to_string)
  |> fn(val) {
    let assert [a, b] = val

    "translate(" <> a <> "," <> b <> ")"
  }
}

pub fn output_to_element(output: Dynamic) -> Attribute(msg) {
  let decoders =
    dynamic.any([
      dynamic.string,
      fn(x) { result.map(dynamic.int(x), fn(o) { int.to_string(o) }) },
      fn(x) { result.map(dynamic.string(x), fn(o) { o }) },
    ])

  decoders(dynamic.from(output))
  |> fn(res) {
    case res {
      Ok(decoded) -> decoded
      Error(_) -> ""
    }
  }
  |> attr("dangerous-unescaped-html", _)
}
