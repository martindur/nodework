import gleam/io
import gleam/list.{shuffle, take}
import gleam/string.{join}

const lib = [
  "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p",
  "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5",
  "6", "7", "8", "9",
]

pub fn generate_random_id(prefix: String) -> String {
  lib
  |> shuffle
  |> take(12)
  |> join("")
  |> fn(id) { prefix <> "-" <> id }
}
