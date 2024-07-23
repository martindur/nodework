import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/set.{type Set}

pub type NodeWork {
  NodeWork(
    label: String,
    inputs: Set(String),
    output: fn(Dict(String, Dynamic)) -> Dynamic,
  )
}
