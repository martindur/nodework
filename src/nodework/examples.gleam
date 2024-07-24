import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/result
import gleam/set
import nodework/flow.{type FlowNode, FlowNode, type ConstNode, ConstNode}

pub fn math_nodes() -> List(FlowNode)  {
  [
    FlowNode("add", set.from_list(["a", "b"]), add),
    FlowNode("double", set.from_list(["x"]), double),
    FlowNode("ten", set.from_list([]), return_ten),
    FlowNode("one", set.from_list([]), return_one)
  ]
}

fn return_ten(inputs: Dict(String, Dynamic)) -> Dynamic {
  dynamic.from(10)
}

fn return_one(inputs: Dict(String, Dynamic)) -> Dynamic {
  dynamic.from(1)
}

fn const_number(input: Dynamic) -> Dynamic {
  let a = result.unwrap(dynamic.int(input), 0)
  dynamic.from(a)
}

fn add(inputs: Dict(String, Dynamic)) -> Dynamic {
  case dict.get(inputs, "a"), dict.get(inputs, "b") {
    Ok(a), Ok(b) -> {
      let a = result.unwrap(dynamic.int(a), 0)
      let b = result.unwrap(dynamic.int(b), 0)

      dynamic.from(a + b)
    }
    Ok(a), Error(_) -> {
      let a = result.unwrap(dynamic.int(a), 0)
      let b = 0

      dynamic.from(a + b)
    }
    Error(_), Ok(b) -> {
      let a = 0
      let b = result.unwrap(dynamic.int(b), 0)

      dynamic.from(a + b)
    }
    _, _ -> dynamic.from(0)
  }
}

fn double(inputs: Dict(String, Dynamic)) -> Dynamic {
  case dict.get(inputs, "x") {
    Ok(x) -> {
      let x = result.unwrap(dynamic.int(x), 0)

      dynamic.from(x * 2)
    }
    Error(_) -> dynamic.from(0)
  }
}
