import gleam/set.{type Set}
import gleam/dict.{type Dict}


pub type IntNode {
  IntNode(identifier: String, inputs: Set(String), output: fn(Dict(String, Int)) -> Int)
}

pub type StringNode {
  StringNode(identifier: String, inputs: Set(String), output: fn(Dict(String, String)) -> String)
}

