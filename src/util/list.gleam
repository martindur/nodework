import gleam/list

pub fn unique_by(list: List(a), criteria: fn(a) -> b) -> List(a) {
  unique_by_acc(list, criteria, [], [])
}

fn unique_by_acc(
  list: List(a),
  criteria: fn(a) -> b,
  seen: List(b),
  acc: List(a),
) -> List(a) {
  case list {
    [] -> list.reverse(acc)
    [head, ..tail] -> {
      let crit = criteria(head)
      case list.contains(seen, crit) {
        True -> unique_by_acc(tail, criteria, seen, acc)
        False -> unique_by_acc(tail, criteria, [crit, ..seen], [head, ..acc])
      }
    }
  }
}
