// build/dev/javascript/prelude.mjs
var CustomType = class {
  withFields(fields) {
    let properties = Object.keys(this).map(
      (label) => label in fields ? fields[label] : this[label]
    );
    return new this.constructor(...properties);
  }
};
var List = class {
  static fromArray(array3, tail) {
    let t = tail || new Empty();
    for (let i = array3.length - 1; i >= 0; --i) {
      t = new NonEmpty(array3[i], t);
    }
    return t;
  }
  [Symbol.iterator]() {
    return new ListIterator(this);
  }
  toArray() {
    return [...this];
  }
  // @internal
  atLeastLength(desired) {
    for (let _ of this) {
      if (desired <= 0)
        return true;
      desired--;
    }
    return desired <= 0;
  }
  // @internal
  hasLength(desired) {
    for (let _ of this) {
      if (desired <= 0)
        return false;
      desired--;
    }
    return desired === 0;
  }
  countLength() {
    let length3 = 0;
    for (let _ of this)
      length3++;
    return length3;
  }
};
function prepend(element2, tail) {
  return new NonEmpty(element2, tail);
}
function toList(elements, tail) {
  return List.fromArray(elements, tail);
}
var ListIterator = class {
  #current;
  constructor(current) {
    this.#current = current;
  }
  next() {
    if (this.#current instanceof Empty) {
      return { done: true };
    } else {
      let { head, tail } = this.#current;
      this.#current = tail;
      return { value: head, done: false };
    }
  }
};
var Empty = class extends List {
};
var NonEmpty = class extends List {
  constructor(head, tail) {
    super();
    this.head = head;
    this.tail = tail;
  }
};
var BitArray = class _BitArray {
  constructor(buffer) {
    if (!(buffer instanceof Uint8Array)) {
      throw "BitArray can only be constructed from a Uint8Array";
    }
    this.buffer = buffer;
  }
  // @internal
  get length() {
    return this.buffer.length;
  }
  // @internal
  byteAt(index2) {
    return this.buffer[index2];
  }
  // @internal
  floatAt(index2) {
    return byteArrayToFloat(this.buffer.slice(index2, index2 + 8));
  }
  // @internal
  intFromSlice(start4, end) {
    return byteArrayToInt(this.buffer.slice(start4, end));
  }
  // @internal
  binaryFromSlice(start4, end) {
    return new _BitArray(this.buffer.slice(start4, end));
  }
  // @internal
  sliceAfter(index2) {
    return new _BitArray(this.buffer.slice(index2));
  }
};
function byteArrayToInt(byteArray) {
  byteArray = byteArray.reverse();
  let value = 0;
  for (let i = byteArray.length - 1; i >= 0; i--) {
    value = value * 256 + byteArray[i];
  }
  return value;
}
function byteArrayToFloat(byteArray) {
  return new Float64Array(byteArray.reverse().buffer)[0];
}
var Result = class _Result extends CustomType {
  // @internal
  static isResult(data) {
    return data instanceof _Result;
  }
};
var Ok = class extends Result {
  constructor(value) {
    super();
    this[0] = value;
  }
  // @internal
  isOk() {
    return true;
  }
};
var Error = class extends Result {
  constructor(detail) {
    super();
    this[0] = detail;
  }
  // @internal
  isOk() {
    return false;
  }
};
function isEqual(x, y) {
  let values = [x, y];
  while (values.length) {
    let a = values.pop();
    let b = values.pop();
    if (a === b)
      continue;
    if (!isObject(a) || !isObject(b))
      return false;
    let unequal = !structurallyCompatibleObjects(a, b) || unequalDates(a, b) || unequalBuffers(a, b) || unequalArrays(a, b) || unequalMaps(a, b) || unequalSets(a, b) || unequalRegExps(a, b);
    if (unequal)
      return false;
    const proto = Object.getPrototypeOf(a);
    if (proto !== null && typeof proto.equals === "function") {
      try {
        if (a.equals(b))
          continue;
        else
          return false;
      } catch {
      }
    }
    let [keys2, get2] = getters(a);
    for (let k of keys2(a)) {
      values.push(get2(a, k), get2(b, k));
    }
  }
  return true;
}
function getters(object3) {
  if (object3 instanceof Map) {
    return [(x) => x.keys(), (x, y) => x.get(y)];
  } else {
    let extra = object3 instanceof globalThis.Error ? ["message"] : [];
    return [(x) => [...extra, ...Object.keys(x)], (x, y) => x[y]];
  }
}
function unequalDates(a, b) {
  return a instanceof Date && (a > b || a < b);
}
function unequalBuffers(a, b) {
  return a.buffer instanceof ArrayBuffer && a.BYTES_PER_ELEMENT && !(a.byteLength === b.byteLength && a.every((n, i) => n === b[i]));
}
function unequalArrays(a, b) {
  return Array.isArray(a) && a.length !== b.length;
}
function unequalMaps(a, b) {
  return a instanceof Map && a.size !== b.size;
}
function unequalSets(a, b) {
  return a instanceof Set && (a.size != b.size || [...a].some((e) => !b.has(e)));
}
function unequalRegExps(a, b) {
  return a instanceof RegExp && (a.source !== b.source || a.flags !== b.flags);
}
function isObject(a) {
  return typeof a === "object" && a !== null;
}
function structurallyCompatibleObjects(a, b) {
  if (typeof a !== "object" && typeof b !== "object" && (!a || !b))
    return false;
  let nonstructural = [Promise, WeakSet, WeakMap, Function];
  if (nonstructural.some((c) => a instanceof c))
    return false;
  return a.constructor === b.constructor;
}
function divideInt(a, b) {
  return Math.trunc(divideFloat(a, b));
}
function divideFloat(a, b) {
  if (b === 0) {
    return 0;
  } else {
    return a / b;
  }
}
function makeError(variant, module, line2, fn, message, extra) {
  let error = new globalThis.Error(message);
  error.gleam_error = variant;
  error.module = module;
  error.line = line2;
  error.fn = fn;
  for (let k in extra)
    error[k] = extra[k];
  return error;
}

// build/dev/javascript/gleam_stdlib/gleam/option.mjs
var Some = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var None = class extends CustomType {
};
function to_result(option, e) {
  if (option instanceof Some) {
    let a = option[0];
    return new Ok(a);
  } else {
    return new Error(e);
  }
}

// build/dev/javascript/gleam_stdlib/gleam/order.mjs
var Lt = class extends CustomType {
};
var Eq = class extends CustomType {
};
var Gt = class extends CustomType {
};

// build/dev/javascript/gleam_stdlib/gleam/float.mjs
function to_string(x) {
  return float_to_string(x);
}
function compare(a, b) {
  let $ = a === b;
  if ($) {
    return new Eq();
  } else {
    let $1 = a < b;
    if ($1) {
      return new Lt();
    } else {
      return new Gt();
    }
  }
}
function min(a, b) {
  let $ = a < b;
  if ($) {
    return a;
  } else {
    return b;
  }
}
function max(a, b) {
  let $ = a > b;
  if ($) {
    return a;
  } else {
    return b;
  }
}
function negate(x) {
  return -1 * x;
}
function do_round(x) {
  let $ = x >= 0;
  if ($) {
    return round(x);
  } else {
    return 0 - round(negate(x));
  }
}
function round2(x) {
  return do_round(x);
}
function add(a, b) {
  return a + b;
}

// build/dev/javascript/gleam_stdlib/gleam/int.mjs
function to_string3(x) {
  return to_string2(x);
}
function to_float(x) {
  return identity(x);
}
function min2(a, b) {
  let $ = a < b;
  if ($) {
    return a;
  } else {
    return b;
  }
}
function max2(a, b) {
  let $ = a > b;
  if ($) {
    return a;
  } else {
    return b;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/pair.mjs
function second(pair) {
  let a = pair[1];
  return a;
}

// build/dev/javascript/gleam_stdlib/gleam/list.mjs
var Ascending = class extends CustomType {
};
var Descending = class extends CustomType {
};
function count_length(loop$list, loop$count) {
  while (true) {
    let list = loop$list;
    let count = loop$count;
    if (list.atLeastLength(1)) {
      let list$1 = list.tail;
      loop$list = list$1;
      loop$count = count + 1;
    } else {
      return count;
    }
  }
}
function length(list) {
  return count_length(list, 0);
}
function do_reverse(loop$remaining, loop$accumulator) {
  while (true) {
    let remaining = loop$remaining;
    let accumulator = loop$accumulator;
    if (remaining.hasLength(0)) {
      return accumulator;
    } else {
      let item = remaining.head;
      let rest$1 = remaining.tail;
      loop$remaining = rest$1;
      loop$accumulator = prepend(item, accumulator);
    }
  }
}
function reverse(xs) {
  return do_reverse(xs, toList([]));
}
function contains(loop$list, loop$elem) {
  while (true) {
    let list = loop$list;
    let elem = loop$elem;
    if (list.hasLength(0)) {
      return false;
    } else if (list.atLeastLength(1) && isEqual(list.head, elem)) {
      let first$1 = list.head;
      return true;
    } else {
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$elem = elem;
    }
  }
}
function first(list) {
  if (list.hasLength(0)) {
    return new Error(void 0);
  } else {
    let x = list.head;
    return new Ok(x);
  }
}
function do_filter(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      let new_acc = (() => {
        let $ = fun(x);
        if ($) {
          return prepend(x, acc);
        } else {
          return acc;
        }
      })();
      loop$list = xs;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter(list, predicate) {
  return do_filter(list, predicate, toList([]));
}
function do_filter_map(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      let new_acc = (() => {
        let $ = fun(x);
        if ($.isOk()) {
          let x$1 = $[0];
          return prepend(x$1, acc);
        } else {
          return acc;
        }
      })();
      loop$list = xs;
      loop$fun = fun;
      loop$acc = new_acc;
    }
  }
}
function filter_map(list, fun) {
  return do_filter_map(list, fun, toList([]));
}
function do_map(loop$list, loop$fun, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      loop$list = xs;
      loop$fun = fun;
      loop$acc = prepend(fun(x), acc);
    }
  }
}
function map(list, fun) {
  return do_map(list, fun, toList([]));
}
function do_index_map(loop$list, loop$fun, loop$index, loop$acc) {
  while (true) {
    let list = loop$list;
    let fun = loop$fun;
    let index2 = loop$index;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse(acc);
    } else {
      let x = list.head;
      let xs = list.tail;
      let acc$1 = prepend(fun(x, index2), acc);
      loop$list = xs;
      loop$fun = fun;
      loop$index = index2 + 1;
      loop$acc = acc$1;
    }
  }
}
function index_map(list, fun) {
  return do_index_map(list, fun, 0, toList([]));
}
function do_take(loop$list, loop$n, loop$acc) {
  while (true) {
    let list = loop$list;
    let n = loop$n;
    let acc = loop$acc;
    let $ = n <= 0;
    if ($) {
      return reverse(acc);
    } else {
      if (list.hasLength(0)) {
        return reverse(acc);
      } else {
        let x = list.head;
        let xs = list.tail;
        loop$list = xs;
        loop$n = n - 1;
        loop$acc = prepend(x, acc);
      }
    }
  }
}
function take(list, n) {
  return do_take(list, n, toList([]));
}
function do_append(loop$first, loop$second) {
  while (true) {
    let first3 = loop$first;
    let second2 = loop$second;
    if (first3.hasLength(0)) {
      return second2;
    } else {
      let item = first3.head;
      let rest$1 = first3.tail;
      loop$first = rest$1;
      loop$second = prepend(item, second2);
    }
  }
}
function append(first3, second2) {
  return do_append(reverse(first3), second2);
}
function prepend2(list, item) {
  return prepend(item, list);
}
function reverse_and_prepend(loop$prefix, loop$suffix) {
  while (true) {
    let prefix = loop$prefix;
    let suffix = loop$suffix;
    if (prefix.hasLength(0)) {
      return suffix;
    } else {
      let first$1 = prefix.head;
      let rest$1 = prefix.tail;
      loop$prefix = rest$1;
      loop$suffix = prepend(first$1, suffix);
    }
  }
}
function do_concat(loop$lists, loop$acc) {
  while (true) {
    let lists = loop$lists;
    let acc = loop$acc;
    if (lists.hasLength(0)) {
      return reverse(acc);
    } else {
      let list = lists.head;
      let further_lists = lists.tail;
      loop$lists = further_lists;
      loop$acc = reverse_and_prepend(list, acc);
    }
  }
}
function concat(lists) {
  return do_concat(lists, toList([]));
}
function fold(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let x = list.head;
      let rest$1 = list.tail;
      loop$list = rest$1;
      loop$initial = fun(initial, x);
      loop$fun = fun;
    }
  }
}
function any(loop$list, loop$predicate) {
  while (true) {
    let list = loop$list;
    let predicate = loop$predicate;
    if (list.hasLength(0)) {
      return false;
    } else {
      let first$1 = list.head;
      let rest$1 = list.tail;
      let $ = predicate(first$1);
      if ($) {
        return true;
      } else {
        loop$list = rest$1;
        loop$predicate = predicate;
      }
    }
  }
}
function sequences(loop$list, loop$compare, loop$growing, loop$direction, loop$prev, loop$acc) {
  while (true) {
    let list = loop$list;
    let compare3 = loop$compare;
    let growing = loop$growing;
    let direction = loop$direction;
    let prev = loop$prev;
    let acc = loop$acc;
    let growing$1 = prepend(prev, growing);
    if (list.hasLength(0)) {
      if (direction instanceof Ascending) {
        return prepend(do_reverse(growing$1, toList([])), acc);
      } else {
        return prepend(growing$1, acc);
      }
    } else {
      let new$1 = list.head;
      let rest$1 = list.tail;
      let $ = compare3(prev, new$1);
      if ($ instanceof Gt && direction instanceof Descending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Lt && direction instanceof Ascending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Eq && direction instanceof Ascending) {
        loop$list = rest$1;
        loop$compare = compare3;
        loop$growing = growing$1;
        loop$direction = direction;
        loop$prev = new$1;
        loop$acc = acc;
      } else if ($ instanceof Gt && direction instanceof Ascending) {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else if ($ instanceof Lt && direction instanceof Descending) {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      } else {
        let acc$1 = (() => {
          if (direction instanceof Ascending) {
            return prepend(do_reverse(growing$1, toList([])), acc);
          } else {
            return prepend(growing$1, acc);
          }
        })();
        if (rest$1.hasLength(0)) {
          return prepend(toList([new$1]), acc$1);
        } else {
          let next = rest$1.head;
          let rest$2 = rest$1.tail;
          let direction$1 = (() => {
            let $1 = compare3(new$1, next);
            if ($1 instanceof Lt) {
              return new Ascending();
            } else if ($1 instanceof Eq) {
              return new Ascending();
            } else {
              return new Descending();
            }
          })();
          loop$list = rest$2;
          loop$compare = compare3;
          loop$growing = toList([new$1]);
          loop$direction = direction$1;
          loop$prev = next;
          loop$acc = acc$1;
        }
      }
    }
  }
}
function merge_ascendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1.hasLength(0)) {
      let list = list2;
      return do_reverse(list, acc);
    } else if (list2.hasLength(0)) {
      let list = list1;
      return do_reverse(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first22 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first22);
      if ($ instanceof Lt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else if ($ instanceof Gt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first22, acc);
      } else {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first22, acc);
      }
    }
  }
}
function merge_ascending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2.hasLength(0)) {
      return do_reverse(acc, toList([]));
    } else if (sequences2.hasLength(1)) {
      let sequence = sequences2.head;
      return do_reverse(
        prepend(do_reverse(sequence, toList([])), acc),
        toList([])
      );
    } else {
      let ascending1 = sequences2.head;
      let ascending2 = sequences2.tail.head;
      let rest$1 = sequences2.tail.tail;
      let descending = merge_ascendings(
        ascending1,
        ascending2,
        compare3,
        toList([])
      );
      loop$sequences = rest$1;
      loop$compare = compare3;
      loop$acc = prepend(descending, acc);
    }
  }
}
function merge_descendings(loop$list1, loop$list2, loop$compare, loop$acc) {
  while (true) {
    let list1 = loop$list1;
    let list2 = loop$list2;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (list1.hasLength(0)) {
      let list = list2;
      return do_reverse(list, acc);
    } else if (list2.hasLength(0)) {
      let list = list1;
      return do_reverse(list, acc);
    } else {
      let first1 = list1.head;
      let rest1 = list1.tail;
      let first22 = list2.head;
      let rest2 = list2.tail;
      let $ = compare3(first1, first22);
      if ($ instanceof Lt) {
        loop$list1 = list1;
        loop$list2 = rest2;
        loop$compare = compare3;
        loop$acc = prepend(first22, acc);
      } else if ($ instanceof Gt) {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      } else {
        loop$list1 = rest1;
        loop$list2 = list2;
        loop$compare = compare3;
        loop$acc = prepend(first1, acc);
      }
    }
  }
}
function merge_descending_pairs(loop$sequences, loop$compare, loop$acc) {
  while (true) {
    let sequences2 = loop$sequences;
    let compare3 = loop$compare;
    let acc = loop$acc;
    if (sequences2.hasLength(0)) {
      return do_reverse(acc, toList([]));
    } else if (sequences2.hasLength(1)) {
      let sequence = sequences2.head;
      return do_reverse(
        prepend(do_reverse(sequence, toList([])), acc),
        toList([])
      );
    } else {
      let descending1 = sequences2.head;
      let descending2 = sequences2.tail.head;
      let rest$1 = sequences2.tail.tail;
      let ascending = merge_descendings(
        descending1,
        descending2,
        compare3,
        toList([])
      );
      loop$sequences = rest$1;
      loop$compare = compare3;
      loop$acc = prepend(ascending, acc);
    }
  }
}
function merge_all(loop$sequences, loop$direction, loop$compare) {
  while (true) {
    let sequences2 = loop$sequences;
    let direction = loop$direction;
    let compare3 = loop$compare;
    if (sequences2.hasLength(0)) {
      return toList([]);
    } else if (sequences2.hasLength(1) && direction instanceof Ascending) {
      let sequence = sequences2.head;
      return sequence;
    } else if (sequences2.hasLength(1) && direction instanceof Descending) {
      let sequence = sequences2.head;
      return do_reverse(sequence, toList([]));
    } else if (direction instanceof Ascending) {
      let sequences$1 = merge_ascending_pairs(sequences2, compare3, toList([]));
      loop$sequences = sequences$1;
      loop$direction = new Descending();
      loop$compare = compare3;
    } else {
      let sequences$1 = merge_descending_pairs(sequences2, compare3, toList([]));
      loop$sequences = sequences$1;
      loop$direction = new Ascending();
      loop$compare = compare3;
    }
  }
}
function sort(list, compare3) {
  if (list.hasLength(0)) {
    return toList([]);
  } else if (list.hasLength(1)) {
    let x = list.head;
    return toList([x]);
  } else {
    let x = list.head;
    let y = list.tail.head;
    let rest$1 = list.tail.tail;
    let direction = (() => {
      let $ = compare3(x, y);
      if ($ instanceof Lt) {
        return new Ascending();
      } else if ($ instanceof Eq) {
        return new Ascending();
      } else {
        return new Descending();
      }
    })();
    let sequences$1 = sequences(
      rest$1,
      compare3,
      toList([x]),
      direction,
      y,
      toList([])
    );
    return merge_all(sequences$1, new Ascending(), compare3);
  }
}
function do_partition(loop$list, loop$categorise, loop$trues, loop$falses) {
  while (true) {
    let list = loop$list;
    let categorise = loop$categorise;
    let trues = loop$trues;
    let falses = loop$falses;
    if (list.hasLength(0)) {
      return [reverse(trues), reverse(falses)];
    } else {
      let x = list.head;
      let xs = list.tail;
      let $ = categorise(x);
      if ($) {
        loop$list = xs;
        loop$categorise = categorise;
        loop$trues = prepend(x, trues);
        loop$falses = falses;
      } else {
        loop$list = xs;
        loop$categorise = categorise;
        loop$trues = trues;
        loop$falses = prepend(x, falses);
      }
    }
  }
}
function partition(list, categorise) {
  return do_partition(list, categorise, toList([]), toList([]));
}
function reduce(list, fun) {
  if (list.hasLength(0)) {
    return new Error(void 0);
  } else {
    let first$1 = list.head;
    let rest$1 = list.tail;
    return new Ok(fold(rest$1, first$1, fun));
  }
}
function do_shuffle_pair_unwrap(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return acc;
    } else {
      let elem_pair = list.head;
      let enumerable = list.tail;
      loop$list = enumerable;
      loop$acc = prepend(elem_pair[1], acc);
    }
  }
}
function do_shuffle_by_pair_indexes(list_of_pairs) {
  return sort(
    list_of_pairs,
    (a_pair, b_pair) => {
      return compare(a_pair[0], b_pair[0]);
    }
  );
}
function shuffle(list) {
  let _pipe = list;
  let _pipe$1 = fold(
    _pipe,
    toList([]),
    (acc, a) => {
      return prepend([random_uniform(), a], acc);
    }
  );
  let _pipe$2 = do_shuffle_by_pair_indexes(_pipe$1);
  return do_shuffle_pair_unwrap(_pipe$2, toList([]));
}

// build/dev/javascript/gleam_stdlib/gleam/result.mjs
function is_ok(result) {
  if (!result.isOk()) {
    return false;
  } else {
    return true;
  }
}
function map2(result, fun) {
  if (result.isOk()) {
    let x = result[0];
    return new Ok(fun(x));
  } else {
    let e = result[0];
    return new Error(e);
  }
}
function map_error(result, fun) {
  if (result.isOk()) {
    let x = result[0];
    return new Ok(x);
  } else {
    let error = result[0];
    return new Error(fun(error));
  }
}
function try$(result, fun) {
  if (result.isOk()) {
    let x = result[0];
    return fun(x);
  } else {
    let e = result[0];
    return new Error(e);
  }
}
function then$(result, fun) {
  return try$(result, fun);
}
function unwrap(result, default$) {
  if (result.isOk()) {
    let v = result[0];
    return v;
  } else {
    return default$;
  }
}

// build/dev/javascript/gleam_stdlib/gleam/string_builder.mjs
function append_builder(builder, suffix) {
  return add2(builder, suffix);
}
function from_strings(strings) {
  return concat2(strings);
}
function from_string(string3) {
  return identity(string3);
}
function append2(builder, second2) {
  return append_builder(builder, from_string(second2));
}
function to_string4(builder) {
  return identity(builder);
}

// build/dev/javascript/gleam_stdlib/gleam/string.mjs
function lowercase2(string3) {
  return lowercase(string3);
}
function uppercase2(string3) {
  return uppercase(string3);
}
function append4(first3, second2) {
  let _pipe = first3;
  let _pipe$1 = from_string(_pipe);
  let _pipe$2 = append2(_pipe$1, second2);
  return to_string4(_pipe$2);
}
function join2(strings, separator) {
  return join(strings, separator);
}
function pop_grapheme2(string3) {
  return pop_grapheme(string3);
}
function capitalise(s) {
  let $ = pop_grapheme2(s);
  if ($.isOk()) {
    let first$1 = $[0][0];
    let rest = $[0][1];
    return append4(uppercase2(first$1), lowercase2(rest));
  } else {
    return "";
  }
}

// build/dev/javascript/gleam_stdlib/gleam/dynamic.mjs
var DecodeError = class extends CustomType {
  constructor(expected, found, path2) {
    super();
    this.expected = expected;
    this.found = found;
    this.path = path2;
  }
};
function from(a) {
  return identity(a);
}
function dynamic(value) {
  return new Ok(value);
}
function classify(data) {
  return classify_dynamic(data);
}
function int(data) {
  return decode_int(data);
}
function float(data) {
  return decode_float(data);
}
function bool(data) {
  return decode_bool(data);
}
function any2(decoders) {
  return (data) => {
    if (decoders.hasLength(0)) {
      return new Error(
        toList([new DecodeError("another type", classify(data), toList([]))])
      );
    } else {
      let decoder = decoders.head;
      let decoders$1 = decoders.tail;
      let $ = decoder(data);
      if ($.isOk()) {
        let decoded = $[0];
        return new Ok(decoded);
      } else {
        return any2(decoders$1)(data);
      }
    }
  };
}
function push_path(error, name) {
  let name$1 = from(name);
  let decoder = any2(
    toList([string, (x) => {
      return map2(int(x), to_string3);
    }])
  );
  let name$2 = (() => {
    let $ = decoder(name$1);
    if ($.isOk()) {
      let name$22 = $[0];
      return name$22;
    } else {
      let _pipe = toList(["<", classify(name$1), ">"]);
      let _pipe$1 = from_strings(_pipe);
      return to_string4(_pipe$1);
    }
  })();
  return error.withFields({ path: prepend(name$2, error.path) });
}
function map_errors(result, f) {
  return map_error(
    result,
    (_capture) => {
      return map(_capture, f);
    }
  );
}
function string(data) {
  return decode_string(data);
}
function field(name, inner_type) {
  return (value) => {
    let missing_field_error = new DecodeError("field", "nothing", toList([]));
    return try$(
      decode_field(value, name),
      (maybe_inner) => {
        let _pipe = maybe_inner;
        let _pipe$1 = to_result(_pipe, toList([missing_field_error]));
        let _pipe$2 = try$(_pipe$1, inner_type);
        return map_errors(
          _pipe$2,
          (_capture) => {
            return push_path(_capture, name);
          }
        );
      }
    );
  };
}

// build/dev/javascript/gleam_stdlib/dict.mjs
var referenceMap = /* @__PURE__ */ new WeakMap();
var tempDataView = new DataView(new ArrayBuffer(8));
var referenceUID = 0;
function hashByReference(o) {
  const known = referenceMap.get(o);
  if (known !== void 0) {
    return known;
  }
  const hash = referenceUID++;
  if (referenceUID === 2147483647) {
    referenceUID = 0;
  }
  referenceMap.set(o, hash);
  return hash;
}
function hashMerge(a, b) {
  return a ^ b + 2654435769 + (a << 6) + (a >> 2) | 0;
}
function hashString(s) {
  let hash = 0;
  const len = s.length;
  for (let i = 0; i < len; i++) {
    hash = Math.imul(31, hash) + s.charCodeAt(i) | 0;
  }
  return hash;
}
function hashNumber(n) {
  tempDataView.setFloat64(0, n);
  const i = tempDataView.getInt32(0);
  const j = tempDataView.getInt32(4);
  return Math.imul(73244475, i >> 16 ^ i) ^ j;
}
function hashBigInt(n) {
  return hashString(n.toString());
}
function hashObject(o) {
  const proto = Object.getPrototypeOf(o);
  if (proto !== null && typeof proto.hashCode === "function") {
    try {
      const code = o.hashCode(o);
      if (typeof code === "number") {
        return code;
      }
    } catch {
    }
  }
  if (o instanceof Promise || o instanceof WeakSet || o instanceof WeakMap) {
    return hashByReference(o);
  }
  if (o instanceof Date) {
    return hashNumber(o.getTime());
  }
  let h = 0;
  if (o instanceof ArrayBuffer) {
    o = new Uint8Array(o);
  }
  if (Array.isArray(o) || o instanceof Uint8Array) {
    for (let i = 0; i < o.length; i++) {
      h = Math.imul(31, h) + getHash(o[i]) | 0;
    }
  } else if (o instanceof Set) {
    o.forEach((v) => {
      h = h + getHash(v) | 0;
    });
  } else if (o instanceof Map) {
    o.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
  } else {
    const keys2 = Object.keys(o);
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      const v = o[k];
      h = h + hashMerge(getHash(v), hashString(k)) | 0;
    }
  }
  return h;
}
function getHash(u) {
  if (u === null)
    return 1108378658;
  if (u === void 0)
    return 1108378659;
  if (u === true)
    return 1108378657;
  if (u === false)
    return 1108378656;
  switch (typeof u) {
    case "number":
      return hashNumber(u);
    case "string":
      return hashString(u);
    case "bigint":
      return hashBigInt(u);
    case "object":
      return hashObject(u);
    case "symbol":
      return hashByReference(u);
    case "function":
      return hashByReference(u);
    default:
      return 0;
  }
}
var SHIFT = 5;
var BUCKET_SIZE = Math.pow(2, SHIFT);
var MASK = BUCKET_SIZE - 1;
var MAX_INDEX_NODE = BUCKET_SIZE / 2;
var MIN_ARRAY_NODE = BUCKET_SIZE / 4;
var ENTRY = 0;
var ARRAY_NODE = 1;
var INDEX_NODE = 2;
var COLLISION_NODE = 3;
var EMPTY = {
  type: INDEX_NODE,
  bitmap: 0,
  array: []
};
function mask(hash, shift) {
  return hash >>> shift & MASK;
}
function bitpos(hash, shift) {
  return 1 << mask(hash, shift);
}
function bitcount(x) {
  x -= x >> 1 & 1431655765;
  x = (x & 858993459) + (x >> 2 & 858993459);
  x = x + (x >> 4) & 252645135;
  x += x >> 8;
  x += x >> 16;
  return x & 127;
}
function index(bitmap, bit) {
  return bitcount(bitmap & bit - 1);
}
function cloneAndSet(arr, at, val) {
  const len = arr.length;
  const out = new Array(len);
  for (let i = 0; i < len; ++i) {
    out[i] = arr[i];
  }
  out[at] = val;
  return out;
}
function spliceIn(arr, at, val) {
  const len = arr.length;
  const out = new Array(len + 1);
  let i = 0;
  let g2 = 0;
  while (i < at) {
    out[g2++] = arr[i++];
  }
  out[g2++] = val;
  while (i < len) {
    out[g2++] = arr[i++];
  }
  return out;
}
function spliceOut(arr, at) {
  const len = arr.length;
  const out = new Array(len - 1);
  let i = 0;
  let g2 = 0;
  while (i < at) {
    out[g2++] = arr[i++];
  }
  ++i;
  while (i < len) {
    out[g2++] = arr[i++];
  }
  return out;
}
function createNode(shift, key1, val1, key2hash, key2, val2) {
  const key1hash = getHash(key1);
  if (key1hash === key2hash) {
    return {
      type: COLLISION_NODE,
      hash: key1hash,
      array: [
        { type: ENTRY, k: key1, v: val1 },
        { type: ENTRY, k: key2, v: val2 }
      ]
    };
  }
  const addedLeaf = { val: false };
  return assoc(
    assocIndex(EMPTY, shift, key1hash, key1, val1, addedLeaf),
    shift,
    key2hash,
    key2,
    val2,
    addedLeaf
  );
}
function assoc(root2, shift, hash, key, val, addedLeaf) {
  switch (root2.type) {
    case ARRAY_NODE:
      return assocArray(root2, shift, hash, key, val, addedLeaf);
    case INDEX_NODE:
      return assocIndex(root2, shift, hash, key, val, addedLeaf);
    case COLLISION_NODE:
      return assocCollision(root2, shift, hash, key, val, addedLeaf);
  }
}
function assocArray(root2, shift, hash, key, val, addedLeaf) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size + 1,
      array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
    };
  }
  if (node.type === ENTRY) {
    if (isEqual(key, node.k)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: ARRAY_NODE,
        size: root2.size,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: ARRAY_NODE,
      size: root2.size,
      array: cloneAndSet(
        root2.array,
        idx,
        createNode(shift + SHIFT, node.k, node.v, hash, key, val)
      )
    };
  }
  const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
  if (n === node) {
    return root2;
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function assocIndex(root2, shift, hash, key, val, addedLeaf) {
  const bit = bitpos(hash, shift);
  const idx = index(root2.bitmap, bit);
  if ((root2.bitmap & bit) !== 0) {
    const node = root2.array[idx];
    if (node.type !== ENTRY) {
      const n = assoc(node, shift + SHIFT, hash, key, val, addedLeaf);
      if (n === node) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    const nodeKey = node.k;
    if (isEqual(key, nodeKey)) {
      if (val === node.v) {
        return root2;
      }
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, {
          type: ENTRY,
          k: key,
          v: val
        })
      };
    }
    addedLeaf.val = true;
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap,
      array: cloneAndSet(
        root2.array,
        idx,
        createNode(shift + SHIFT, nodeKey, node.v, hash, key, val)
      )
    };
  } else {
    const n = root2.array.length;
    if (n >= MAX_INDEX_NODE) {
      const nodes = new Array(32);
      const jdx = mask(hash, shift);
      nodes[jdx] = assocIndex(EMPTY, shift + SHIFT, hash, key, val, addedLeaf);
      let j = 0;
      let bitmap = root2.bitmap;
      for (let i = 0; i < 32; i++) {
        if ((bitmap & 1) !== 0) {
          const node = root2.array[j++];
          nodes[i] = node;
        }
        bitmap = bitmap >>> 1;
      }
      return {
        type: ARRAY_NODE,
        size: n + 1,
        array: nodes
      };
    } else {
      const newArray = spliceIn(root2.array, idx, {
        type: ENTRY,
        k: key,
        v: val
      });
      addedLeaf.val = true;
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap | bit,
        array: newArray
      };
    }
  }
}
function assocCollision(root2, shift, hash, key, val, addedLeaf) {
  if (hash === root2.hash) {
    const idx = collisionIndexOf(root2, key);
    if (idx !== -1) {
      const entry = root2.array[idx];
      if (entry.v === val) {
        return root2;
      }
      return {
        type: COLLISION_NODE,
        hash,
        array: cloneAndSet(root2.array, idx, { type: ENTRY, k: key, v: val })
      };
    }
    const size = root2.array.length;
    addedLeaf.val = true;
    return {
      type: COLLISION_NODE,
      hash,
      array: cloneAndSet(root2.array, size, { type: ENTRY, k: key, v: val })
    };
  }
  return assoc(
    {
      type: INDEX_NODE,
      bitmap: bitpos(root2.hash, shift),
      array: [root2]
    },
    shift,
    hash,
    key,
    val,
    addedLeaf
  );
}
function collisionIndexOf(root2, key) {
  const size = root2.array.length;
  for (let i = 0; i < size; i++) {
    if (isEqual(key, root2.array[i].k)) {
      return i;
    }
  }
  return -1;
}
function find(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return findArray(root2, shift, hash, key);
    case INDEX_NODE:
      return findIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return findCollision(root2, key);
  }
}
function findArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    return void 0;
  }
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return void 0;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    return find(node, shift + SHIFT, hash, key);
  }
  if (isEqual(key, node.k)) {
    return node;
  }
  return void 0;
}
function findCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return void 0;
  }
  return root2.array[idx];
}
function without(root2, shift, hash, key) {
  switch (root2.type) {
    case ARRAY_NODE:
      return withoutArray(root2, shift, hash, key);
    case INDEX_NODE:
      return withoutIndex(root2, shift, hash, key);
    case COLLISION_NODE:
      return withoutCollision(root2, key);
  }
}
function withoutArray(root2, shift, hash, key) {
  const idx = mask(hash, shift);
  const node = root2.array[idx];
  if (node === void 0) {
    return root2;
  }
  let n = void 0;
  if (node.type === ENTRY) {
    if (!isEqual(node.k, key)) {
      return root2;
    }
  } else {
    n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
  }
  if (n === void 0) {
    if (root2.size <= MIN_ARRAY_NODE) {
      const arr = root2.array;
      const out = new Array(root2.size - 1);
      let i = 0;
      let j = 0;
      let bitmap = 0;
      while (i < idx) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      ++i;
      while (i < arr.length) {
        const nv = arr[i];
        if (nv !== void 0) {
          out[j] = nv;
          bitmap |= 1 << i;
          ++j;
        }
        ++i;
      }
      return {
        type: INDEX_NODE,
        bitmap,
        array: out
      };
    }
    return {
      type: ARRAY_NODE,
      size: root2.size - 1,
      array: cloneAndSet(root2.array, idx, n)
    };
  }
  return {
    type: ARRAY_NODE,
    size: root2.size,
    array: cloneAndSet(root2.array, idx, n)
  };
}
function withoutIndex(root2, shift, hash, key) {
  const bit = bitpos(hash, shift);
  if ((root2.bitmap & bit) === 0) {
    return root2;
  }
  const idx = index(root2.bitmap, bit);
  const node = root2.array[idx];
  if (node.type !== ENTRY) {
    const n = without(node, shift + SHIFT, hash, key);
    if (n === node) {
      return root2;
    }
    if (n !== void 0) {
      return {
        type: INDEX_NODE,
        bitmap: root2.bitmap,
        array: cloneAndSet(root2.array, idx, n)
      };
    }
    if (root2.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  if (isEqual(key, node.k)) {
    if (root2.bitmap === bit) {
      return void 0;
    }
    return {
      type: INDEX_NODE,
      bitmap: root2.bitmap ^ bit,
      array: spliceOut(root2.array, idx)
    };
  }
  return root2;
}
function withoutCollision(root2, key) {
  const idx = collisionIndexOf(root2, key);
  if (idx < 0) {
    return root2;
  }
  if (root2.array.length === 1) {
    return void 0;
  }
  return {
    type: COLLISION_NODE,
    hash: root2.hash,
    array: spliceOut(root2.array, idx)
  };
}
function forEach(root2, fn) {
  if (root2 === void 0) {
    return;
  }
  const items = root2.array;
  const size = items.length;
  for (let i = 0; i < size; i++) {
    const item = items[i];
    if (item === void 0) {
      continue;
    }
    if (item.type === ENTRY) {
      fn(item.v, item.k);
      continue;
    }
    forEach(item, fn);
  }
}
var Dict = class _Dict {
  /**
   * @template V
   * @param {Record<string,V>} o
   * @returns {Dict<string,V>}
   */
  static fromObject(o) {
    const keys2 = Object.keys(o);
    let m = _Dict.new();
    for (let i = 0; i < keys2.length; i++) {
      const k = keys2[i];
      m = m.set(k, o[k]);
    }
    return m;
  }
  /**
   * @template K,V
   * @param {Map<K,V>} o
   * @returns {Dict<K,V>}
   */
  static fromMap(o) {
    let m = _Dict.new();
    o.forEach((v, k) => {
      m = m.set(k, v);
    });
    return m;
  }
  static new() {
    return new _Dict(void 0, 0);
  }
  /**
   * @param {undefined | Node<K,V>} root
   * @param {number} size
   */
  constructor(root2, size) {
    this.root = root2;
    this.size = size;
  }
  /**
   * @template NotFound
   * @param {K} key
   * @param {NotFound} notFound
   * @returns {NotFound | V}
   */
  get(key, notFound) {
    if (this.root === void 0) {
      return notFound;
    }
    const found = find(this.root, 0, getHash(key), key);
    if (found === void 0) {
      return notFound;
    }
    return found.v;
  }
  /**
   * @param {K} key
   * @param {V} val
   * @returns {Dict<K,V>}
   */
  set(key, val) {
    const addedLeaf = { val: false };
    const root2 = this.root === void 0 ? EMPTY : this.root;
    const newRoot = assoc(root2, 0, getHash(key), key, val, addedLeaf);
    if (newRoot === this.root) {
      return this;
    }
    return new _Dict(newRoot, addedLeaf.val ? this.size + 1 : this.size);
  }
  /**
   * @param {K} key
   * @returns {Dict<K,V>}
   */
  delete(key) {
    if (this.root === void 0) {
      return this;
    }
    const newRoot = without(this.root, 0, getHash(key), key);
    if (newRoot === this.root) {
      return this;
    }
    if (newRoot === void 0) {
      return _Dict.new();
    }
    return new _Dict(newRoot, this.size - 1);
  }
  /**
   * @param {K} key
   * @returns {boolean}
   */
  has(key) {
    if (this.root === void 0) {
      return false;
    }
    return find(this.root, 0, getHash(key), key) !== void 0;
  }
  /**
   * @returns {[K,V][]}
   */
  entries() {
    if (this.root === void 0) {
      return [];
    }
    const result = [];
    this.forEach((v, k) => result.push([k, v]));
    return result;
  }
  /**
   *
   * @param {(val:V,key:K)=>void} fn
   */
  forEach(fn) {
    forEach(this.root, fn);
  }
  hashCode() {
    let h = 0;
    this.forEach((v, k) => {
      h = h + hashMerge(getHash(v), getHash(k)) | 0;
    });
    return h;
  }
  /**
   * @param {unknown} o
   * @returns {boolean}
   */
  equals(o) {
    if (!(o instanceof _Dict) || this.size !== o.size) {
      return false;
    }
    let equal = true;
    this.forEach((v, k) => {
      equal = equal && isEqual(o.get(k, !v), v);
    });
    return equal;
  }
};

// build/dev/javascript/gleam_stdlib/gleam_stdlib.mjs
var Nil = void 0;
var NOT_FOUND = {};
function identity(x) {
  return x;
}
function to_string2(term) {
  return term.toString();
}
function float_to_string(float3) {
  const string3 = float3.toString();
  if (string3.indexOf(".") >= 0) {
    return string3;
  } else {
    return string3 + ".0";
  }
}
function graphemes_iterator(string3) {
  if (Intl && Intl.Segmenter) {
    return new Intl.Segmenter().segment(string3)[Symbol.iterator]();
  }
}
function pop_grapheme(string3) {
  let first3;
  const iterator = graphemes_iterator(string3);
  if (iterator) {
    first3 = iterator.next().value?.segment;
  } else {
    first3 = string3.match(/./su)?.[0];
  }
  if (first3) {
    return new Ok([first3, string3.slice(first3.length)]);
  } else {
    return new Error(Nil);
  }
}
function lowercase(string3) {
  return string3.toLowerCase();
}
function uppercase(string3) {
  return string3.toUpperCase();
}
function add2(a, b) {
  return a + b;
}
function join(xs, separator) {
  const iterator = xs[Symbol.iterator]();
  let result = iterator.next().value || "";
  let current = iterator.next();
  while (!current.done) {
    result = result + separator + current.value;
    current = iterator.next();
  }
  return result;
}
function concat2(xs) {
  let result = "";
  for (const x of xs) {
    result = result + x;
  }
  return result;
}
var unicode_whitespaces = [
  " ",
  // Space
  "	",
  // Horizontal tab
  "\n",
  // Line feed
  "\v",
  // Vertical tab
  "\f",
  // Form feed
  "\r",
  // Carriage return
  "\x85",
  // Next line
  "\u2028",
  // Line separator
  "\u2029"
  // Paragraph separator
].join();
var left_trim_regex = new RegExp(`^([${unicode_whitespaces}]*)`, "g");
var right_trim_regex = new RegExp(`([${unicode_whitespaces}]*)$`, "g");
function round(float3) {
  return Math.round(float3);
}
function random_uniform() {
  const random_uniform_result = Math.random();
  if (random_uniform_result === 1) {
    return random_uniform();
  }
  return random_uniform_result;
}
function new_map() {
  return Dict.new();
}
function map_size(map4) {
  return map4.size;
}
function map_to_list(map4) {
  return List.fromArray(map4.entries());
}
function map_remove(key, map4) {
  return map4.delete(key);
}
function map_get(map4, key) {
  const value = map4.get(key, NOT_FOUND);
  if (value === NOT_FOUND) {
    return new Error(Nil);
  }
  return new Ok(value);
}
function map_insert(key, value, map4) {
  return map4.set(key, value);
}
function classify_dynamic(data) {
  if (typeof data === "string") {
    return "String";
  } else if (typeof data === "boolean") {
    return "Bool";
  } else if (data instanceof Result) {
    return "Result";
  } else if (data instanceof List) {
    return "List";
  } else if (data instanceof BitArray) {
    return "BitArray";
  } else if (data instanceof Dict) {
    return "Dict";
  } else if (Number.isInteger(data)) {
    return "Int";
  } else if (Array.isArray(data)) {
    return `Tuple of ${data.length} elements`;
  } else if (typeof data === "number") {
    return "Float";
  } else if (data === null) {
    return "Null";
  } else if (data === void 0) {
    return "Nil";
  } else {
    const type = typeof data;
    return type.charAt(0).toUpperCase() + type.slice(1);
  }
}
function decoder_error(expected, got) {
  return decoder_error_no_classify(expected, classify_dynamic(got));
}
function decoder_error_no_classify(expected, got) {
  return new Error(
    List.fromArray([new DecodeError(expected, got, List.fromArray([]))])
  );
}
function decode_string(data) {
  return typeof data === "string" ? new Ok(data) : decoder_error("String", data);
}
function decode_int(data) {
  return Number.isInteger(data) ? new Ok(data) : decoder_error("Int", data);
}
function decode_float(data) {
  return typeof data === "number" ? new Ok(data) : decoder_error("Float", data);
}
function decode_bool(data) {
  return typeof data === "boolean" ? new Ok(data) : decoder_error("Bool", data);
}
function decode_field(value, name) {
  const not_a_map_error = () => decoder_error("Dict", value);
  if (value instanceof Dict || value instanceof WeakMap || value instanceof Map) {
    const entry = map_get(value, name);
    return new Ok(entry.isOk() ? new Some(entry[0]) : new None());
  } else if (value === null) {
    return not_a_map_error();
  } else if (Object.getPrototypeOf(value) == Object.prototype) {
    return try_get_field(value, name, () => new Ok(new None()));
  } else {
    return try_get_field(value, name, not_a_map_error);
  }
}
function try_get_field(value, field2, or_else) {
  try {
    return field2 in value ? new Ok(new Some(value[field2])) : or_else();
  } catch {
    return or_else();
  }
}

// build/dev/javascript/gleam_stdlib/gleam/dict.mjs
function new$() {
  return new_map();
}
function get(from3, get2) {
  return map_get(from3, get2);
}
function insert(dict, key, value) {
  return map_insert(key, value, dict);
}
function fold_list_of_pair(loop$list, loop$initial) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let x = list.head;
      let rest = list.tail;
      loop$list = rest;
      loop$initial = insert(initial, x[0], x[1]);
    }
  }
}
function from_list(list) {
  return fold_list_of_pair(list, new$());
}
function reverse_and_concat(loop$remaining, loop$accumulator) {
  while (true) {
    let remaining = loop$remaining;
    let accumulator = loop$accumulator;
    if (remaining.hasLength(0)) {
      return accumulator;
    } else {
      let item = remaining.head;
      let rest = remaining.tail;
      loop$remaining = rest;
      loop$accumulator = prepend(item, accumulator);
    }
  }
}
function do_keys_acc(loop$list, loop$acc) {
  while (true) {
    let list = loop$list;
    let acc = loop$acc;
    if (list.hasLength(0)) {
      return reverse_and_concat(acc, toList([]));
    } else {
      let x = list.head;
      let xs = list.tail;
      loop$list = xs;
      loop$acc = prepend(x[0], acc);
    }
  }
}
function do_keys(dict) {
  let list_of_pairs = map_to_list(dict);
  return do_keys_acc(list_of_pairs, toList([]));
}
function keys(dict) {
  return do_keys(dict);
}
function insert_taken(loop$dict, loop$desired_keys, loop$acc) {
  while (true) {
    let dict = loop$dict;
    let desired_keys = loop$desired_keys;
    let acc = loop$acc;
    let insert$1 = (taken, key) => {
      let $ = get(dict, key);
      if ($.isOk()) {
        let value = $[0];
        return insert(taken, key, value);
      } else {
        return taken;
      }
    };
    if (desired_keys.hasLength(0)) {
      return acc;
    } else {
      let x = desired_keys.head;
      let xs = desired_keys.tail;
      loop$dict = dict;
      loop$desired_keys = xs;
      loop$acc = insert$1(acc, x);
    }
  }
}
function do_take2(desired_keys, dict) {
  return insert_taken(dict, desired_keys, new$());
}
function take3(dict, desired_keys) {
  return do_take2(desired_keys, dict);
}
function insert_pair(dict, pair) {
  return insert(dict, pair[0], pair[1]);
}
function fold_inserts(loop$new_entries, loop$dict) {
  while (true) {
    let new_entries = loop$new_entries;
    let dict = loop$dict;
    if (new_entries.hasLength(0)) {
      return dict;
    } else {
      let x = new_entries.head;
      let xs = new_entries.tail;
      loop$new_entries = xs;
      loop$dict = insert_pair(dict, x);
    }
  }
}
function do_merge(dict, new_entries) {
  let _pipe = new_entries;
  let _pipe$1 = map_to_list(_pipe);
  return fold_inserts(_pipe$1, dict);
}
function merge(dict, new_entries) {
  return do_merge(dict, new_entries);
}
function delete$(dict, key) {
  return map_remove(key, dict);
}
function drop2(loop$dict, loop$disallowed_keys) {
  while (true) {
    let dict = loop$dict;
    let disallowed_keys = loop$disallowed_keys;
    if (disallowed_keys.hasLength(0)) {
      return dict;
    } else {
      let x = disallowed_keys.head;
      let xs = disallowed_keys.tail;
      loop$dict = delete$(dict, x);
      loop$disallowed_keys = xs;
    }
  }
}
function do_fold(loop$list, loop$initial, loop$fun) {
  while (true) {
    let list = loop$list;
    let initial = loop$initial;
    let fun = loop$fun;
    if (list.hasLength(0)) {
      return initial;
    } else {
      let k = list.head[0];
      let v = list.head[1];
      let rest = list.tail;
      loop$list = rest;
      loop$initial = fun(initial, k, v);
      loop$fun = fun;
    }
  }
}
function fold2(dict, initial, fun) {
  let _pipe = dict;
  let _pipe$1 = map_to_list(_pipe);
  return do_fold(_pipe$1, initial, fun);
}
function do_map_values(f, dict) {
  let f$1 = (dict2, k, v) => {
    return insert(dict2, k, f(k, v));
  };
  let _pipe = dict;
  return fold2(_pipe, new$(), f$1);
}
function map_values(dict, fun) {
  return do_map_values(fun, dict);
}

// build/dev/javascript/gleam_stdlib/gleam/set.mjs
var Set2 = class extends CustomType {
  constructor(dict) {
    super();
    this.dict = dict;
  }
};
function new$2() {
  return new Set2(new$());
}
function contains2(set, member) {
  let _pipe = set.dict;
  let _pipe$1 = get(_pipe, member);
  return is_ok(_pipe$1);
}
function to_list2(set) {
  return keys(set.dict);
}
function take4(set, desired) {
  return new Set2(take3(set.dict, desired));
}
function order(first3, second2) {
  let $ = map_size(first3.dict) > map_size(second2.dict);
  if ($) {
    return [first3, second2];
  } else {
    return [second2, first3];
  }
}
function intersection(first3, second2) {
  let $ = order(first3, second2);
  let larger = $[0];
  let smaller = $[1];
  return take4(larger, to_list2(smaller));
}
var token = void 0;
function insert2(set, member) {
  return new Set2(insert(set.dict, member, token));
}
function from_list2(members) {
  let dict = fold(
    members,
    new$(),
    (m, k) => {
      return insert(m, k, token);
    }
  );
  return new Set2(dict);
}

// build/dev/javascript/gleam_stdlib/gleam/bool.mjs
function guard(requirement, consequence, alternative) {
  if (requirement) {
    return consequence;
  } else {
    return alternative();
  }
}

// build/dev/javascript/lustre/lustre/effect.mjs
var Effect = class extends CustomType {
  constructor(all) {
    super();
    this.all = all;
  }
};
function from2(effect) {
  return new Effect(toList([(dispatch2, _) => {
    return effect(dispatch2);
  }]));
}
function none() {
  return new Effect(toList([]));
}
function batch(effects) {
  return new Effect(
    fold(
      effects,
      toList([]),
      (b, _use1) => {
        let a = _use1.all;
        return append(b, a);
      }
    )
  );
}

// build/dev/javascript/lustre/lustre/internals/vdom.mjs
var Text = class extends CustomType {
  constructor(content) {
    super();
    this.content = content;
  }
};
var Element = class extends CustomType {
  constructor(key, namespace2, tag, attrs, children, self_closing, void$) {
    super();
    this.key = key;
    this.namespace = namespace2;
    this.tag = tag;
    this.attrs = attrs;
    this.children = children;
    this.self_closing = self_closing;
    this.void = void$;
  }
};
var Attribute = class extends CustomType {
  constructor(x0, x1, as_property) {
    super();
    this[0] = x0;
    this[1] = x1;
    this.as_property = as_property;
  }
};
var Event = class extends CustomType {
  constructor(x0, x1) {
    super();
    this[0] = x0;
    this[1] = x1;
  }
};

// build/dev/javascript/lustre/lustre/attribute.mjs
function attribute(name, value) {
  return new Attribute(name, from(value), false);
}
function on(name, handler) {
  return new Event("on" + name, handler);
}
function style(properties) {
  return attribute(
    "style",
    fold(
      properties,
      "",
      (styles, _use1) => {
        let name$1 = _use1[0];
        let value$1 = _use1[1];
        return styles + name$1 + ":" + value$1 + ";";
      }
    )
  );
}
function class$(name) {
  return attribute("class", name);
}
function id(name) {
  return attribute("id", name);
}

// build/dev/javascript/lustre/lustre/element.mjs
function element(tag, attrs, children) {
  if (tag === "area") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "base") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "br") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "col") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "embed") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "hr") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "img") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "input") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "link") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "meta") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "param") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "source") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "track") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else if (tag === "wbr") {
    return new Element("", "", tag, attrs, toList([]), false, true);
  } else {
    return new Element("", "", tag, attrs, children, false, false);
  }
}
function namespaced(namespace2, tag, attrs, children) {
  return new Element("", namespace2, tag, attrs, children, false, false);
}
function text(content) {
  return new Text(content);
}
function none2() {
  return new Text("");
}

// build/dev/javascript/lustre/lustre/internals/runtime.mjs
var Debug = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Dispatch = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var Shutdown = class extends CustomType {
};
var ForceModel = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};

// build/dev/javascript/lustre/vdom.ffi.mjs
function morph(prev, next, dispatch2, isComponent = false) {
  let out;
  let stack = [{ prev, next, parent: prev.parentNode }];
  while (stack.length) {
    let { prev: prev2, next: next2, parent } = stack.pop();
    if (next2.subtree !== void 0)
      next2 = next2.subtree();
    if (next2.content !== void 0) {
      if (!prev2) {
        const created = document.createTextNode(next2.content);
        parent.appendChild(created);
        out ??= created;
      } else if (prev2.nodeType === Node.TEXT_NODE) {
        if (prev2.textContent !== next2.content)
          prev2.textContent = next2.content;
        out ??= prev2;
      } else {
        const created = document.createTextNode(next2.content);
        parent.replaceChild(created, prev2);
        out ??= created;
      }
    } else if (next2.tag !== void 0) {
      const created = createElementNode({
        prev: prev2,
        next: next2,
        dispatch: dispatch2,
        stack,
        isComponent
      });
      if (!prev2) {
        parent.appendChild(created);
      } else if (prev2 !== created) {
        parent.replaceChild(created, prev2);
      }
      out ??= created;
    } else if (next2.elements !== void 0) {
      iterateElement(next2, (fragmentElement) => {
        stack.unshift({ prev: prev2, next: fragmentElement, parent });
        prev2 = prev2?.nextSibling;
      });
    } else if (next2.subtree !== void 0) {
      stack.push({ prev: prev2, next: next2, parent });
    }
  }
  return out;
}
function createElementNode({ prev, next, dispatch: dispatch2, stack }) {
  const namespace2 = next.namespace || "http://www.w3.org/1999/xhtml";
  const canMorph = prev && prev.nodeType === Node.ELEMENT_NODE && prev.localName === next.tag && prev.namespaceURI === (next.namespace || "http://www.w3.org/1999/xhtml");
  const el2 = canMorph ? prev : namespace2 ? document.createElementNS(namespace2, next.tag) : document.createElement(next.tag);
  let handlersForEl;
  if (!registeredHandlers.has(el2)) {
    const emptyHandlers = /* @__PURE__ */ new Map();
    registeredHandlers.set(el2, emptyHandlers);
    handlersForEl = emptyHandlers;
  } else {
    handlersForEl = registeredHandlers.get(el2);
  }
  const prevHandlers = canMorph ? new Set(handlersForEl.keys()) : null;
  const prevAttributes = canMorph ? new Set(Array.from(prev.attributes, (a) => a.name)) : null;
  let className = null;
  let style2 = null;
  let innerHTML = null;
  for (const attr of next.attrs) {
    const name = attr[0];
    const value = attr[1];
    if (attr.as_property) {
      if (el2[name] !== value)
        el2[name] = value;
      if (canMorph)
        prevAttributes.delete(name);
    } else if (name.startsWith("on")) {
      const eventName = name.slice(2);
      const callback = dispatch2(value);
      if (!handlersForEl.has(eventName)) {
        el2.addEventListener(eventName, lustreGenericEventHandler);
      }
      handlersForEl.set(eventName, callback);
      if (canMorph)
        prevHandlers.delete(eventName);
    } else if (name.startsWith("data-lustre-on-")) {
      const eventName = name.slice(15);
      const callback = dispatch2(lustreServerEventHandler);
      if (!handlersForEl.has(eventName)) {
        el2.addEventListener(eventName, lustreGenericEventHandler);
      }
      handlersForEl.set(eventName, callback);
      el2.setAttribute(name, value);
    } else if (name === "class") {
      className = className === null ? value : className + " " + value;
    } else if (name === "style") {
      style2 = style2 === null ? value : style2 + value;
    } else if (name === "dangerous-unescaped-html") {
      innerHTML = value;
    } else {
      if (el2.getAttribute(name) !== value)
        el2.setAttribute(name, value);
      if (name === "value" || name === "selected")
        el2[name] = value;
      if (canMorph)
        prevAttributes.delete(name);
    }
  }
  if (className !== null) {
    el2.setAttribute("class", className);
    if (canMorph)
      prevAttributes.delete("class");
  }
  if (style2 !== null) {
    el2.setAttribute("style", style2);
    if (canMorph)
      prevAttributes.delete("style");
  }
  if (canMorph) {
    for (const attr of prevAttributes) {
      el2.removeAttribute(attr);
    }
    for (const eventName of prevHandlers) {
      handlersForEl.delete(eventName);
      el2.removeEventListener(eventName, lustreGenericEventHandler);
    }
  }
  if (next.key !== void 0 && next.key !== "") {
    el2.setAttribute("data-lustre-key", next.key);
  } else if (innerHTML !== null) {
    el2.innerHTML = innerHTML;
    return el2;
  }
  let prevChild = el2.firstChild;
  let seenKeys = null;
  let keyedChildren = null;
  let incomingKeyedChildren = null;
  let firstChild = next.children[Symbol.iterator]().next().value;
  if (canMorph && firstChild !== void 0 && // Explicit checks are more verbose but truthy checks force a bunch of comparisons
  // we don't care about: it's never gonna be a number etc.
  firstChild.key !== void 0 && firstChild.key !== "") {
    seenKeys = /* @__PURE__ */ new Set();
    keyedChildren = getKeyedChildren(prev);
    incomingKeyedChildren = getKeyedChildren(next);
  }
  for (const child of next.children) {
    iterateElement(child, (currElement) => {
      if (currElement.key !== void 0 && seenKeys !== null) {
        prevChild = diffKeyedChild(
          prevChild,
          currElement,
          el2,
          stack,
          incomingKeyedChildren,
          keyedChildren,
          seenKeys
        );
      } else {
        stack.unshift({ prev: prevChild, next: currElement, parent: el2 });
        prevChild = prevChild?.nextSibling;
      }
    });
  }
  while (prevChild) {
    const next2 = prevChild.nextSibling;
    el2.removeChild(prevChild);
    prevChild = next2;
  }
  return el2;
}
var registeredHandlers = /* @__PURE__ */ new WeakMap();
function lustreGenericEventHandler(event2) {
  const target = event2.currentTarget;
  if (!registeredHandlers.has(target)) {
    target.removeEventListener(event2.type, lustreGenericEventHandler);
    return;
  }
  const handlersForEventTarget = registeredHandlers.get(target);
  if (!handlersForEventTarget.has(event2.type)) {
    target.removeEventListener(event2.type, lustreGenericEventHandler);
    return;
  }
  handlersForEventTarget.get(event2.type)(event2);
}
function lustreServerEventHandler(event2) {
  const el2 = event2.currentTarget;
  const tag = el2.getAttribute(`data-lustre-on-${event2.type}`);
  const data = JSON.parse(el2.getAttribute("data-lustre-data") || "{}");
  const include = JSON.parse(el2.getAttribute("data-lustre-include") || "[]");
  switch (event2.type) {
    case "input":
    case "change":
      include.push("target.value");
      break;
  }
  return {
    tag,
    data: include.reduce(
      (data2, property) => {
        const path2 = property.split(".");
        for (let i = 0, o = data2, e = event2; i < path2.length; i++) {
          if (i === path2.length - 1) {
            o[path2[i]] = e[path2[i]];
          } else {
            o[path2[i]] ??= {};
            e = e[path2[i]];
            o = o[path2[i]];
          }
        }
        return data2;
      },
      { data }
    )
  };
}
function getKeyedChildren(el2) {
  const keyedChildren = /* @__PURE__ */ new Map();
  if (el2) {
    for (const child of el2.children) {
      iterateElement(child, (currElement) => {
        const key = currElement?.key || currElement?.getAttribute?.("data-lustre-key");
        if (key)
          keyedChildren.set(key, currElement);
      });
    }
  }
  return keyedChildren;
}
function diffKeyedChild(prevChild, child, el2, stack, incomingKeyedChildren, keyedChildren, seenKeys) {
  while (prevChild && !incomingKeyedChildren.has(prevChild.getAttribute("data-lustre-key"))) {
    const nextChild = prevChild.nextSibling;
    el2.removeChild(prevChild);
    prevChild = nextChild;
  }
  if (keyedChildren.size === 0) {
    iterateElement(child, (currChild) => {
      stack.unshift({ prev: prevChild, next: currChild, parent: el2 });
      prevChild = prevChild?.nextSibling;
    });
    return prevChild;
  }
  if (seenKeys.has(child.key)) {
    console.warn(`Duplicate key found in Lustre vnode: ${child.key}`);
    stack.unshift({ prev: null, next: child, parent: el2 });
    return prevChild;
  }
  seenKeys.add(child.key);
  const keyedChild = keyedChildren.get(child.key);
  if (!keyedChild && !prevChild) {
    stack.unshift({ prev: null, next: child, parent: el2 });
    return prevChild;
  }
  if (!keyedChild && prevChild !== null) {
    const placeholder = document.createTextNode("");
    el2.insertBefore(placeholder, prevChild);
    stack.unshift({ prev: placeholder, next: child, parent: el2 });
    return prevChild;
  }
  if (!keyedChild || keyedChild === prevChild) {
    stack.unshift({ prev: prevChild, next: child, parent: el2 });
    prevChild = prevChild?.nextSibling;
    return prevChild;
  }
  el2.insertBefore(keyedChild, prevChild);
  stack.unshift({ prev: keyedChild, next: child, parent: el2 });
  return prevChild;
}
function iterateElement(element2, processElement) {
  if (element2.elements !== void 0) {
    for (const currElement of element2.elements) {
      processElement(currElement);
    }
  } else {
    processElement(element2);
  }
}

// build/dev/javascript/lustre/client-runtime.ffi.mjs
var LustreClientApplication2 = class _LustreClientApplication {
  #root = null;
  #queue = [];
  #effects = [];
  #didUpdate = false;
  #isComponent = false;
  #model = null;
  #update = null;
  #view = null;
  static start(flags, selector, init3, update2, view2) {
    if (!is_browser())
      return new Error(new NotABrowser());
    const root2 = selector instanceof HTMLElement ? selector : document.querySelector(selector);
    if (!root2)
      return new Error(new ElementNotFound(selector));
    const app = new _LustreClientApplication(init3(flags), update2, view2, root2);
    return new Ok((msg) => app.send(msg));
  }
  constructor([model, effects], update2, view2, root2 = document.body, isComponent = false) {
    this.#model = model;
    this.#update = update2;
    this.#view = view2;
    this.#root = root2;
    this.#effects = effects.all.toArray();
    this.#didUpdate = true;
    this.#isComponent = isComponent;
    window.requestAnimationFrame(() => this.#tick());
  }
  send(action) {
    switch (true) {
      case action instanceof Dispatch: {
        this.#queue.push(action[0]);
        this.#tick();
        return;
      }
      case action instanceof Shutdown: {
        this.#shutdown();
        return;
      }
      case action instanceof Debug: {
        this.#debug(action[0]);
        return;
      }
      default:
        return;
    }
  }
  emit(event2, data) {
    this.#root.dispatchEvent(
      new CustomEvent(event2, {
        bubbles: true,
        detail: data,
        composed: true
      })
    );
  }
  #tick() {
    this.#flush_queue();
    if (this.#didUpdate) {
      const vdom = this.#view(this.#model);
      const dispatch2 = (handler) => (e) => {
        const result = handler(e);
        if (result instanceof Ok) {
          this.send(new Dispatch(result[0]));
        }
      };
      this.#didUpdate = false;
      this.#root = morph(this.#root, vdom, dispatch2, this.#isComponent);
    }
  }
  #flush_queue(iterations = 0) {
    while (this.#queue.length) {
      const [next, effects] = this.#update(this.#model, this.#queue.shift());
      this.#didUpdate ||= this.#model !== next;
      this.#model = next;
      this.#effects = this.#effects.concat(effects.all.toArray());
    }
    while (this.#effects.length) {
      this.#effects.shift()(
        (msg) => this.send(new Dispatch(msg)),
        (event2, data) => this.emit(event2, data)
      );
    }
    if (this.#queue.length) {
      if (iterations < 5) {
        this.#flush_queue(++iterations);
      } else {
        window.requestAnimationFrame(() => this.#tick());
      }
    }
  }
  #debug(action) {
    switch (true) {
      case action instanceof ForceModel: {
        const vdom = this.#view(action[0]);
        const dispatch2 = (handler) => (e) => {
          const result = handler(e);
          if (result instanceof Ok) {
            this.send(new Dispatch(result[0]));
          }
        };
        this.#queue = [];
        this.#effects = [];
        this.#didUpdate = false;
        this.#root = morph(this.#root, vdom, dispatch2, this.#isComponent);
      }
    }
  }
  #shutdown() {
    this.#root.remove();
    this.#root = null;
    this.#model = null;
    this.#queue = [];
    this.#effects = [];
    this.#didUpdate = false;
    this.#update = () => {
    };
    this.#view = () => {
    };
  }
};
var start = (app, selector, flags) => LustreClientApplication2.start(
  flags,
  selector,
  app.init,
  app.update,
  app.view
);
var is_browser = () => globalThis.window && window.document;
var stop_propagation = (event2) => event2.stopPropagation();

// build/dev/javascript/lustre/lustre.mjs
var App = class extends CustomType {
  constructor(init3, update2, view2, on_attribute_change) {
    super();
    this.init = init3;
    this.update = update2;
    this.view = view2;
    this.on_attribute_change = on_attribute_change;
  }
};
var ElementNotFound = class extends CustomType {
  constructor(selector) {
    super();
    this.selector = selector;
  }
};
var NotABrowser = class extends CustomType {
};
function application(init3, update2, view2) {
  return new App(init3, update2, view2, new None());
}
function dispatch(msg) {
  return new Dispatch(msg);
}
function start3(app, selector, flags) {
  return guard(
    !is_browser(),
    new Error(new NotABrowser()),
    () => {
      return start(app, selector, flags);
    }
  );
}

// build/dev/javascript/lustre/lustre/element/html.mjs
function div(attrs, children) {
  return element("div", attrs, children);
}
function p(attrs, children) {
  return element("p", attrs, children);
}
function button(attrs, children) {
  return element("button", attrs, children);
}

// build/dev/javascript/lustre/lustre/element/svg.mjs
var namespace = "http://www.w3.org/2000/svg";
function circle(attrs) {
  return namespaced(namespace, "circle", attrs, toList([]));
}
function line(attrs) {
  return namespaced(namespace, "line", attrs, toList([]));
}
function rect(attrs) {
  return namespaced(namespace, "rect", attrs, toList([]));
}
function defs(attrs, children) {
  return namespaced(namespace, "defs", attrs, children);
}
function g(attrs, children) {
  return namespaced(namespace, "g", attrs, children);
}
function pattern(attrs, children) {
  return namespaced(namespace, "pattern", attrs, children);
}
function svg(attrs, children) {
  return namespaced(namespace, "svg", attrs, children);
}
function path(attrs) {
  return namespaced(namespace, "path", attrs, toList([]));
}
function text2(attrs, content) {
  return namespaced(namespace, "text", attrs, toList([text(content)]));
}

// build/dev/javascript/lustre/lustre/event.mjs
function on2(name, handler) {
  return on(name, handler);
}
function on_mouse_down(msg) {
  return on2("mousedown", (_) => {
    return new Ok(msg);
  });
}
function on_mouse_up(msg) {
  return on2("mouseup", (_) => {
    return new Ok(msg);
  });
}
function on_mouse_enter(msg) {
  return on2("mouseenter", (_) => {
    return new Ok(msg);
  });
}
function on_mouse_leave(msg) {
  return on2("mouseleave", (_) => {
    return new Ok(msg);
  });
}
function mouse_position(event2) {
  return then$(
    field("clientX", float)(event2),
    (x) => {
      return then$(
        field("clientY", float)(event2),
        (y) => {
          return new Ok([x, y]);
        }
      );
    }
  );
}

// build/dev/javascript/nodework/nodework.ffi.mjs
function documentResizeEventListener(listener) {
  return window.addEventListener("resize", listener);
}
function mouseUpEventListener(listener) {
  return window.addEventListener("mouseup", listener);
}
function windowSize() {
  return [window.innerWidth, window.innerHeight];
}

// build/dev/javascript/nodework/nodework/vector.mjs
var Vector = class extends CustomType {
  constructor(x, y) {
    super();
    this.x = x;
    this.y = y;
  }
};
var Translate = class extends CustomType {
};
var Scale = class extends CustomType {
};
function subtract(a, b) {
  return new Vector(b.x - a.x, b.y - a.y);
}
function add3(a, b) {
  return new Vector(a.x + b.x, a.y + b.y);
}
function map_vector(vec, f) {
  return new Vector(f(vec.x), f(vec.y));
}
function scalar(vec, b) {
  let _pipe = vec;
  return map_vector(
    _pipe,
    (val) => {
      let _pipe$1 = val;
      let _pipe$2 = to_float(_pipe$1);
      let _pipe$3 = ((x) => {
        return x * b;
      })(_pipe$2);
      return round2(_pipe$3);
    }
  );
}
function divide(vec, b) {
  let _pipe = vec;
  return map_vector(
    _pipe,
    (val) => {
      let _pipe$1 = val;
      let _pipe$2 = to_float(_pipe$1);
      let _pipe$3 = ((x) => {
        return divideFloat(x, b);
      })(_pipe$2);
      return round2(_pipe$3);
    }
  );
}
function bounded_vector(vec, bound) {
  let _pipe = vec;
  return map_vector(
    _pipe,
    (val) => {
      let _pipe$1 = min2(val, bound);
      return max2(_pipe$1, bound * -1);
    }
  );
}
function inverse(p2) {
  return new Vector(p2.x * -1, p2.y * -1);
}
function to_html(vec, t) {
  let _pipe = (() => {
    if (t instanceof Translate) {
      return "translate(";
    } else if (t instanceof Scale) {
      return "scale(";
    } else {
      return "rotate(";
    }
  })();
  return ((t2) => {
    return t2 + to_string3(vec.x) + "," + to_string3(vec.y) + ")";
  })(_pipe);
}

// build/dev/javascript/nodework/nodework/conn.mjs
var Conn = class extends CustomType {
  constructor(id2, p0, p1, source_node_id, target_node_id, target_input_id, target_input_value, active) {
    super();
    this.id = id2;
    this.p0 = p0;
    this.p1 = p1;
    this.source_node_id = source_node_id;
    this.target_node_id = target_node_id;
    this.target_input_id = target_input_id;
    this.target_input_value = target_input_value;
    this.active = active;
  }
};
function to_attributes(conn) {
  return toList([
    attribute("x1", to_string3(conn.p0.x)),
    attribute("y1", to_string3(conn.p0.y)),
    attribute("x2", to_string3(conn.p1.x)),
    attribute("y2", to_string3(conn.p1.y))
  ]);
}
function conn_duplicate(a, b) {
  return a.target_input_id === b.target_input_id;
}
function deduplicate_helper(loop$remaining, loop$seen) {
  while (true) {
    let remaining = loop$remaining;
    let seen = loop$seen;
    if (remaining.hasLength(0)) {
      return seen;
    } else {
      let head = remaining.head;
      let tail = remaining.tail;
      let $ = any(seen, (x) => {
        return conn_duplicate(x, head);
      });
      if ($) {
        loop$remaining = tail;
        loop$seen = seen;
      } else {
        loop$remaining = tail;
        loop$seen = prepend(head, seen);
      }
    }
  }
}
function unique(conns) {
  return deduplicate_helper(conns, toList([]));
}
function map_active(conns, f) {
  let _pipe = conns;
  return map(
    _pipe,
    (c) => {
      let $ = c.active;
      if (!$) {
        return c;
      } else {
        return f(c);
      }
    }
  );
}
function exclude_by_node_ids(conns, ids) {
  let _pipe = conns;
  return filter(
    _pipe,
    (c) => {
      let _pipe$1 = from_list2(toList([c.source_node_id, c.target_node_id]));
      let _pipe$2 = intersection(_pipe$1, ids);
      let _pipe$3 = to_list2(_pipe$2);
      return ((x) => {
        if (x.hasLength(0)) {
          return true;
        } else {
          return false;
        }
      })(_pipe$3);
    }
  );
}

// build/dev/javascript/nodework/nodework/navigator.mjs
var Navigator = class extends CustomType {
  constructor(cursor_point2, mouse_down) {
    super();
    this.cursor_point = cursor_point2;
    this.mouse_down = mouse_down;
  }
};
function set_navigator_mouse_down(nav) {
  return nav.withFields({ mouse_down: true });
}

// build/dev/javascript/nodework/util/random.mjs
var lib = /* @__PURE__ */ toList([
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9"
]);
function generate_random_id(prefix) {
  let _pipe = lib;
  let _pipe$1 = shuffle(_pipe);
  let _pipe$2 = take(_pipe$1, 12);
  let _pipe$3 = join2(_pipe$2, "");
  return ((id2) => {
    return prefix + "." + id2;
  })(_pipe$3);
}

// build/dev/javascript/nodework/nodework/node.mjs
var Node2 = class extends CustomType {
  constructor(position, offset, id2, inputs, output2, name) {
    super();
    this.position = position;
    this.offset = offset;
    this.id = id2;
    this.inputs = inputs;
    this.output = output2;
    this.name = name;
  }
};
var NodeFunction = class extends CustomType {
  constructor(label, inputs, output2) {
    super();
    this.label = label;
    this.inputs = inputs;
    this.output = output2;
  }
};
var NotFound = class extends CustomType {
};
var NodeInput = class extends CustomType {
  constructor(id2, position, label, hovered) {
    super();
    this.id = id2;
    this.position = position;
    this.label = label;
    this.hovered = hovered;
  }
};
var NodeOutput = class extends CustomType {
  constructor(id2, position, hovered) {
    super();
    this.id = id2;
    this.position = position;
    this.hovered = hovered;
  }
};
function input_position_from_index(index2) {
  return new Vector(0, 50 + index2 * 30);
}
function new_input(id2, index2, label) {
  let _pipe = id2 + "-" + to_string3(index2);
  return ((input_id2) => {
    return new NodeInput(
      input_id2,
      input_position_from_index(index2),
      label,
      false
    );
  })(_pipe);
}
function input_id(in$) {
  return in$.id;
}
function input_label(in$) {
  return in$.label;
}
function input_hovered(in$) {
  return in$.hovered;
}
function input_position(in$) {
  return in$.position;
}
function set_input_hover(ins, id2) {
  let _pipe = ins;
  return map_values(
    _pipe,
    (_, node) => {
      let _pipe$1 = node.inputs;
      let _pipe$2 = map(
        _pipe$1,
        (input) => {
          let _pipe$22 = input.id === id2;
          return ((hovered) => {
            return input.withFields({ hovered });
          })(
            _pipe$22
          );
        }
      );
      return ((inputs) => {
        return node.withFields({ inputs });
      })(
        _pipe$2
      );
    }
  );
}
function reset_input_hover(ins) {
  let _pipe = ins;
  return map_values(
    _pipe,
    (_, node) => {
      let _pipe$1 = node.inputs;
      let _pipe$2 = map(
        _pipe$1,
        (input) => {
          return input.withFields({ hovered: false });
        }
      );
      return ((inputs) => {
        return node.withFields({ inputs });
      })(
        _pipe$2
      );
    }
  );
}
function set_output_hover(ins, id2) {
  let _pipe = ins;
  return map_values(
    _pipe,
    (_, node) => {
      let _pipe$1 = (() => {
        let $ = node.output.id === id2;
        if ($) {
          return node.output.withFields({ hovered: true });
        } else {
          return node.output;
        }
      })();
      return ((output2) => {
        return node.withFields({ output: output2 });
      })(
        _pipe$1
      );
    }
  );
}
function reset_output_hover(ins) {
  let _pipe = ins;
  return map_values(
    _pipe,
    (_, node) => {
      let _pipe$1 = node.output.withFields({ hovered: false });
      return ((output2) => {
        return node.withFields({ output: output2 });
      })(
        _pipe$1
      );
    }
  );
}
function get_node_from_input_hovered(ins) {
  let _pipe = ins;
  let _pipe$1 = map_to_list(_pipe);
  let _pipe$2 = map(_pipe$1, second);
  let _pipe$3 = filter_map(
    _pipe$2,
    (node) => {
      let $ = (() => {
        let _pipe$32 = node.inputs;
        return filter(_pipe$32, (in$) => {
          return in$.hovered;
        });
      })();
      if ($.hasLength(0)) {
        return new Error(void 0);
      } else if ($.hasLength(1)) {
        let input = $.head;
        return new Ok([node, input]);
      } else {
        return new Error(void 0);
      }
    }
  );
  return ((nodes) => {
    if (nodes.hasLength(1)) {
      let node_and_input = nodes.head;
      return new Ok(node_and_input);
    } else if (nodes.hasLength(0)) {
      return new Error(new NotFound());
    } else {
      return new Error(new NotFound());
    }
  })(_pipe$3);
}
function new_output(id2) {
  return new NodeOutput("out-" + id2, new Vector(200, 50), false);
}
function output_position(out) {
  return out.position;
}
function output_id(out) {
  return out.id;
}
function output_hovered(out) {
  return out.hovered;
}
function get_position(nodes, id2) {
  let _pipe = nodes;
  let _pipe$1 = get(_pipe, id2);
  return ((r) => {
    if (r.isOk()) {
      let n = r[0];
      return n.position;
    } else {
      return new Vector(0, 0);
    }
  })(_pipe$1);
}
function update_offset(node, point) {
  let _pipe = node.position;
  let _pipe$1 = subtract(_pipe, point);
  return ((p2) => {
    return node.withFields({ offset: p2 });
  })(_pipe$1);
}
function update_all_node_offsets(nodes, point) {
  let _pipe = nodes;
  return map_values(
    _pipe,
    (_, node) => {
      return update_offset(node, point);
    }
  );
}
function exclude_by_ids(nodes, ids) {
  let _pipe = nodes;
  return drop2(_pipe, to_list2(ids));
}
function new_node(library, identifier, position) {
  let _pipe = library;
  let _pipe$1 = get(_pipe, identifier);
  return ((res) => {
    if (!res.isOk() && !res[0]) {
      return new Error(void 0);
    } else {
      let node_function = res[0];
      let id2 = (() => {
        let $ = lowercase2(node_function.label) === "output";
        if ($) {
          return "node.output";
        } else {
          return generate_random_id("node");
        }
      })();
      return new Ok(
        new Node2(
          position,
          new Vector(0, 0),
          id2,
          (() => {
            let _pipe$2 = node_function.inputs;
            let _pipe$3 = to_list2(_pipe$2);
            return index_map(
              _pipe$3,
              (label, i) => {
                return new_input(id2, i, label);
              }
            );
          })(),
          new_output(id2),
          capitalise(node_function.label)
        )
      );
    }
  })(_pipe$1);
}

// build/dev/javascript/nodework/nodework/dag.mjs
var Vertex = class extends CustomType {
  constructor(id2, value, inputs) {
    super();
    this.id = id2;
    this.value = value;
    this.inputs = inputs;
  }
};
var Edge = class extends CustomType {
  constructor(from3, to, input) {
    super();
    this.from = from3;
    this.to = to;
    this.input = input;
  }
};
var Graph = class extends CustomType {
  constructor(verts, edges) {
    super();
    this.verts = verts;
    this.edges = edges;
  }
};
function new$4() {
  return new Graph(new$(), toList([]));
}
function sync_vertex_inputs(graph) {
  let _pipe = graph.verts;
  let _pipe$1 = map_values(
    _pipe,
    (id2, v) => {
      let _pipe$12 = graph.edges;
      let _pipe$2 = filter(_pipe$12, (edge) => {
        return id2 === edge.to;
      });
      let _pipe$3 = map(_pipe$2, (edge) => {
        return [edge.input, edge.from];
      });
      let _pipe$4 = from_list(_pipe$3);
      return ((inputs) => {
        return v.withFields({ inputs });
      })(_pipe$4);
    }
  );
  return ((verts) => {
    return graph.withFields({ verts });
  })(_pipe$1);
}
function prune(edges, verts) {
  let ids = map(verts, (v) => {
    return v.id;
  });
  let _pipe = edges;
  let _pipe$1 = partition(
    _pipe,
    (e) => {
      return contains(ids, e.to) || contains(ids, e.from);
    }
  );
  return ((x) => {
    return second(x);
  })(_pipe$1);
}
function indegree(vert, edges) {
  let _pipe = edges;
  let _pipe$1 = filter(_pipe, (edge) => {
    return edge.to === vert.id;
  });
  return length(_pipe$1);
}
function partition_source_verts(verts, edges) {
  let _pipe = verts;
  return partition(
    _pipe,
    (vert) => {
      return indegree(vert, edges) === 0;
    }
  );
}
function sort2(sorted, unsorted, edges) {
  let edges$1 = prune(edges, sorted);
  let _pipe = unsorted;
  let _pipe$1 = partition_source_verts(_pipe, edges$1);
  return ((res) => {
    if (res[0].hasLength(0) && res[1].hasLength(0)) {
      return new Ok(sorted);
    } else if (res[1].hasLength(0)) {
      let source = res[0];
      return new Ok(append(sorted, source));
    } else if (res[0].hasLength(0)) {
      return new Error("Cyclical relationship detected");
    } else {
      let source = res[0];
      let rest = res[1];
      let sorted$1 = append(sorted, source);
      let $ = sort2(sorted$1, rest, edges$1);
      if ($.isOk()) {
        let res$1 = $[0];
        return new Ok(res$1);
      } else {
        let err = $[0];
        return new Error(err);
      }
    }
  })(_pipe$1);
}
function topological_sort(graph) {
  return sort2(
    toList([]),
    (() => {
      let _pipe = graph.verts;
      let _pipe$1 = map_to_list(_pipe);
      return map(_pipe$1, second);
    })(),
    graph.edges
  );
}

// build/dev/javascript/nodework/nodework/menu.mjs
var Menu = class extends CustomType {
  constructor(pos, active, nodes) {
    super();
    this.pos = pos;
    this.active = active;
    this.nodes = nodes;
  }
};
function view_menu_item(item, spawn_func) {
  let text3 = item[0];
  let id2 = item[1];
  return button(
    toList([
      id(id2),
      class$("hover:bg-gray-300"),
      on2("click", spawn_func)
    ]),
    toList([text(text3)])
  );
}
function view_menu(menu, spawn_func) {
  let pos = "translate(" + to_string3(menu.pos.x) + "px, " + to_string3(
    menu.pos.y
  ) + "px)";
  return div(
    (() => {
      let $ = menu.active;
      if ($) {
        return toList([
          class$(
            "absolute top-0 left-0 w-[100px] h-[300px] bg-gray-200 rounded shadow"
          ),
          style(toList([["transform", pos]]))
        ]);
      } else {
        return toList([class$("hidden")]);
      }
    })(),
    toList([
      div(
        toList([class$("flex flex-col p-2 gap-1")]),
        (() => {
          let _pipe = menu.nodes;
          return map(
            _pipe,
            (item) => {
              return view_menu_item(item, spawn_func);
            }
          );
        })()
      )
    ])
  );
}
function new$5(nodes) {
  let _pipe = nodes;
  let _pipe$1 = map(
    _pipe,
    (node) => {
      return [capitalise(node.label), lowercase2(node.label)];
    }
  );
  return ((nodes2) => {
    return new Menu(new Vector(0, 0), false, nodes2);
  })(
    _pipe$1
  );
}

// build/dev/javascript/nodework/nodework/viewbox.mjs
var Normal = class extends CustomType {
};
var Drag = class extends CustomType {
};
var ViewBox = class extends CustomType {
  constructor(offset, resolution, zoom_level) {
    super();
    this.offset = offset;
    this.resolution = resolution;
    this.zoom_level = zoom_level;
  }
};
function to_viewbox_scale(vb, p2) {
  let _pipe = p2;
  return scalar(_pipe, vb.zoom_level);
}
function to_viewbox_translate(vb, p2) {
  let _pipe = p2;
  return add3(_pipe, vb.offset);
}
function to_viewbox_space(vb, p2) {
  let _pipe = p2;
  let _pipe$1 = scalar(_pipe, vb.zoom_level);
  return add3(_pipe$1, vb.offset);
}
function from_viewbox_scale(vb, p2) {
  let _pipe = p2;
  return divide(_pipe, vb.zoom_level);
}
function update_resolution(vb, resolution) {
  let _pipe = vb.zoom_level;
  let _pipe$1 = ((_capture) => {
    return scalar(resolution, _capture);
  })(
    _pipe
  );
  return ((res) => {
    return vb.withFields({ resolution: res });
  })(_pipe$1);
}
var scroll_factor = 0.1;
var limit_zoom_in = 0.5;
var limit_zoom_out = 3;
function update_zoom_level(vb, delta_y) {
  let _pipe = delta_y;
  let _pipe$1 = ((d) => {
    let $ = d > 0;
    if ($) {
      return 1 * scroll_factor;
    } else {
      return -1 * scroll_factor;
    }
  })(_pipe);
  let _pipe$2 = add(_pipe$1, vb.zoom_level);
  let _pipe$3 = min(_pipe$2, limit_zoom_out);
  let _pipe$4 = max(_pipe$3, limit_zoom_in);
  return ((zoom) => {
    return vb.withFields({ zoom_level: zoom });
  })(_pipe$4);
}

// build/dev/javascript/nodework/nodework/model.mjs
var Model = class extends CustomType {
  constructor(nodes, connections2, nodes_selected, window_resolution, viewbox, navigator, mode, last_clicked_point, menu, library, graph, output2) {
    super();
    this.nodes = nodes;
    this.connections = connections2;
    this.nodes_selected = nodes_selected;
    this.window_resolution = window_resolution;
    this.viewbox = viewbox;
    this.navigator = navigator;
    this.mode = mode;
    this.last_clicked_point = last_clicked_point;
    this.menu = menu;
    this.library = library;
    this.graph = graph;
    this.output = output2;
  }
};

// build/dev/javascript/nodework/nodework/calc.mjs
function nodes_to_vertices(nodes) {
  let _pipe = nodes;
  return map(
    _pipe,
    (n) => {
      return [n.id, new Vertex(n.id, lowercase2(n.name), new$())];
    }
  );
}
function conns_to_edges(conns) {
  let _pipe = conns;
  return map(
    _pipe,
    (c) => {
      return new Edge(c.source_node_id, c.target_node_id, c.target_input_value);
    }
  );
}
function filter_conns_by_edges(conns, edges) {
  let edge_source_ids = map(edges, (e) => {
    return e.from;
  });
  let _pipe = conns;
  return filter(
    _pipe,
    (c) => {
      return contains(edge_source_ids, c.source_node_id);
    }
  );
}
function sync_verts(model) {
  let _pipe = model.nodes;
  let _pipe$1 = map_to_list(_pipe);
  let _pipe$2 = map(_pipe$1, second);
  let _pipe$3 = nodes_to_vertices(_pipe$2);
  let _pipe$4 = from_list(_pipe$3);
  let _pipe$5 = ((verts) => {
    return model.graph.withFields({ verts });
  })(
    _pipe$4
  );
  return ((graph) => {
    return model.withFields({ graph });
  })(_pipe$5);
}
function sync_edges(model) {
  let _pipe = model.connections;
  let _pipe$1 = conns_to_edges(_pipe);
  let _pipe$2 = ((edges) => {
    return model.graph.withFields({ edges });
  })(
    _pipe$1
  );
  return ((graph) => {
    let $ = topological_sort(graph);
    if ($.isOk()) {
      return model.withFields({ graph });
    } else {
      let _pipe$3 = filter_conns_by_edges(model.connections, model.graph.edges);
      return ((conns) => {
        return model.withFields({ graph: model.graph, connections: conns });
      })(_pipe$3);
    }
  })(_pipe$2);
}
function eval_graph(verts, model) {
  let _pipe = verts;
  let _pipe$1 = fold(
    _pipe,
    new$(),
    (evaluated, vert) => {
      let $ = get(model.library, vert.value);
      if (!$.isOk() && !$[0]) {
        return insert(evaluated, vert.id, from(0));
      } else {
        let nodefunc = $[0];
        let inputs = (() => {
          let _pipe$13 = vert.inputs;
          let _pipe$23 = map_to_list(_pipe$13);
          let _pipe$32 = map(
            _pipe$23,
            (keypair) => {
              let ref = keypair[0];
              let key = keypair[1];
              let $1 = get(evaluated, key);
              if (!$1.isOk() && !$1[0]) {
                return [ref, from(0)];
              } else {
                let val = $1[0];
                return [ref, val];
              }
            }
          );
          return from_list(_pipe$32);
        })();
        let _pipe$12 = inputs;
        let _pipe$22 = nodefunc.output(_pipe$12);
        return ((val) => {
          return insert(evaluated, vert.id, val);
        })(
          _pipe$22
        );
      }
    }
  );
  let _pipe$2 = get(_pipe$1, "node.output");
  let _pipe$3 = ((res) => {
    if (res.isOk()) {
      let output2 = res[0];
      return output2;
    } else {
      return from(0);
    }
  })(_pipe$2);
  return ((output2) => {
    return model.withFields({ output: output2 });
  })(_pipe$3);
}
function recalc_graph(model) {
  let _pipe = model.graph;
  let _pipe$1 = sync_vertex_inputs(_pipe);
  let _pipe$2 = topological_sort(_pipe$1);
  let _pipe$3 = ((res) => {
    if (res.isOk()) {
      let verts = res[0];
      return verts;
    } else {
      let msg = res[0];
      return toList([]);
    }
  })(_pipe$2);
  return eval_graph(_pipe$3, model);
}

// build/dev/javascript/nodework/nodework/draw.mjs
function cursor_point(m, p2) {
  let _pipe = p2;
  let _pipe$1 = ((_capture) => {
    return to_viewbox_scale(m.viewbox, _capture);
  })(_pipe);
  let _pipe$2 = ((p3) => {
    return m.navigator.withFields({ cursor_point: p3 });
  })(
    _pipe$1
  );
  return ((nav) => {
    return m.withFields({ navigator: nav });
  })(_pipe$2);
}
function viewbox_offset(m, limit) {
  let _pipe = (() => {
    let $ = m.mode;
    if ($ instanceof Normal) {
      return m.viewbox.offset;
    } else {
      let _pipe2 = m.navigator.cursor_point;
      let _pipe$12 = ((_capture) => {
        return subtract(m.last_clicked_point, _capture);
      })(_pipe2);
      let _pipe$2 = inverse(_pipe$12);
      return bounded_vector(_pipe$2, limit);
    }
  })();
  let _pipe$1 = ((offset) => {
    return m.viewbox.withFields({ offset });
  })(
    _pipe
  );
  return ((vb) => {
    return m.withFields({ viewbox: vb });
  })(_pipe$1);
}
function node_positions(m) {
  let _pipe = m.nodes_selected;
  let _pipe$1 = to_list2(_pipe);
  let _pipe$2 = ((_capture) => {
    return take3(m.nodes, _capture);
  })(
    _pipe$1
  );
  let _pipe$3 = map_values(
    _pipe$2,
    (_, node) => {
      let $ = m.navigator.mouse_down;
      if (!$) {
        return node;
      } else {
        return node.withFields({
          position: subtract(node.offset, m.navigator.cursor_point)
        });
      }
    }
  );
  let _pipe$4 = ((_capture) => {
    return merge(m.nodes, _capture);
  })(
    _pipe$3
  );
  return ((nodes) => {
    return m.withFields({ nodes });
  })(_pipe$4);
}
function dragged_connection(m) {
  let point = (p2) => {
    return to_viewbox_translate(m.viewbox, p2);
  };
  let _pipe = m.connections;
  let _pipe$1 = map(
    _pipe,
    (c) => {
      let $ = c.active;
      if ($) {
        return c.withFields({ p1: point(m.navigator.cursor_point) });
      } else {
        return c;
      }
    }
  );
  return ((conns) => {
    return m.withFields({ connections: conns });
  })(_pipe$1);
}
function order_connection_nodes(nodes, c) {
  let $ = first(nodes);
  if (!$.isOk() && !$[0]) {
    return toList([]);
  } else {
    let node = $[0];
    let $1 = node.id === c.source_node_id;
    if ($1) {
      return nodes;
    } else {
      return reverse(nodes);
    }
  }
}
function delete_selected_nodes(m) {
  let _pipe = m.nodes;
  let _pipe$1 = exclude_by_ids(_pipe, m.nodes_selected);
  return ((nodes) => {
    return m.withFields({ nodes });
  })(_pipe$1);
}
function delete_orphaned_connections(m) {
  let _pipe = m.connections;
  let _pipe$1 = exclude_by_node_ids(_pipe, m.nodes_selected);
  return ((conns) => {
    return m.withFields({ connections: conns });
  })(_pipe$1);
}
function connections(m) {
  let _pipe = m.connections;
  let _pipe$1 = map(
    _pipe,
    (c) => {
      let _pipe$12 = take3(
        m.nodes,
        toList([c.source_node_id, c.target_node_id])
      );
      let _pipe$2 = map_to_list(_pipe$12);
      let _pipe$3 = map(_pipe$2, second);
      let _pipe$4 = order_connection_nodes(_pipe$3, c);
      return ((nodes) => {
        if (nodes.hasLength(0)) {
          return c;
        } else if (nodes.hasLength(1)) {
          return c;
        } else if (nodes.hasLength(2)) {
          let a = nodes.head;
          let b = nodes.tail.head;
          return c.withFields({
            p0: add3(a.position, output_position(a.output)),
            p1: (() => {
              let _pipe$5 = b.inputs;
              let _pipe$6 = filter(
                _pipe$5,
                (in$) => {
                  return input_id(in$) === c.target_input_id;
                }
              );
              let _pipe$7 = ((nodes2) => {
                if (!nodes2.hasLength(1)) {
                  throw makeError(
                    "assignment_no_match",
                    "nodework/draw",
                    104,
                    "",
                    "Assignment pattern did not match",
                    { value: nodes2 }
                  );
                }
                let x = nodes2.head;
                return x;
              })(_pipe$6);
              let _pipe$8 = ((x) => {
                return input_position(x);
              })(
                _pipe$7
              );
              return ((_capture) => {
                return add3(b.position, _capture);
              })(
                _pipe$8
              );
            })()
          });
        } else {
          return c;
        }
      })(_pipe$4);
    }
  );
  return ((conns) => {
    return m.withFields({ connections: conns });
  })(_pipe$1);
}

// build/dev/javascript/nodework/nodework/examples.mjs
function output(inputs) {
  let $ = get(inputs, "eval");
  if ($.isOk()) {
    let eval$ = $[0];
    return eval$;
  } else {
    return from(0);
  }
}
function return_ten(inputs) {
  return from(10);
}
function return_one(inputs) {
  return from(1);
}
function add4(inputs) {
  let $ = get(inputs, "a");
  let $1 = get(inputs, "b");
  if ($.isOk() && $1.isOk()) {
    let a = $[0];
    let b = $1[0];
    let a$1 = unwrap(int(a), 0);
    let b$1 = unwrap(int(b), 0);
    return from(a$1 + b$1);
  } else if ($.isOk() && !$1.isOk()) {
    let a = $[0];
    let a$1 = unwrap(int(a), 0);
    let b = 0;
    return from(a$1 + b);
  } else if (!$.isOk() && $1.isOk()) {
    let b = $1[0];
    let a = 0;
    let b$1 = unwrap(int(b), 0);
    return from(a + b$1);
  } else {
    return from(0);
  }
}
function double(inputs) {
  let $ = get(inputs, "x");
  if ($.isOk()) {
    let x = $[0];
    let x$1 = unwrap(int(x), 0);
    return from(x$1 * 2);
  } else {
    return from(0);
  }
}
function math_nodes() {
  return toList([
    new NodeFunction("add", from_list2(toList(["a", "b"])), add4),
    new NodeFunction("double", from_list2(toList(["x"])), double),
    new NodeFunction("ten", from_list2(toList([])), return_ten),
    new NodeFunction("one", from_list2(toList([])), return_one),
    new NodeFunction("output", from_list2(toList(["eval"])), output)
  ]);
}

// build/dev/javascript/nodework/nodework.mjs
var MouseEvent = class extends CustomType {
  constructor(position, shift_key_active) {
    super();
    this.position = position;
    this.shift_key_active = shift_key_active;
  }
};
var UserAddedNode = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserMovedMouse = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserClickedNode = class extends CustomType {
  constructor(x0, x1) {
    super();
    this[0] = x0;
    this[1] = x1;
  }
};
var UserUnclickedNode = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserClickedNodeOutput = class extends CustomType {
  constructor(x0, x1) {
    super();
    this[0] = x0;
    this[1] = x1;
  }
};
var UserUnclicked = class extends CustomType {
};
var UserClickedConn = class extends CustomType {
  constructor(x0, x1) {
    super();
    this[0] = x0;
    this[1] = x1;
  }
};
var UserClickedGraph = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserScrolled = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserHoverNodeInput = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserUnhoverNodeInput = class extends CustomType {
};
var UserHoverNodeOutput = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var UserUnhoverNodeOutput = class extends CustomType {
};
var UserPressedKey = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var GraphClearSelection = class extends CustomType {
};
var GraphSetDragMode = class extends CustomType {
};
var GraphSetNormalMode = class extends CustomType {
};
var GraphAddNodeToSelection = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var GraphSetNodeAsSelection = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var GraphResizeViewBox = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var GraphOpenMenu = class extends CustomType {
};
var GraphCloseMenu = class extends CustomType {
};
var GraphSpawnNode = class extends CustomType {
  constructor(x0) {
    super();
    this[0] = x0;
  }
};
var GraphDeleteSelectedNodes = class extends CustomType {
};
function get_window_size() {
  let _pipe = windowSize();
  return ((z) => {
    let x = z[0];
    let y = z[1];
    return new Vector(x, y);
  })(_pipe);
}
function setup(runtime_call) {
  documentResizeEventListener(
    (_) => {
      let _pipe = get_window_size();
      let _pipe$1 = new GraphResizeViewBox(_pipe);
      let _pipe$2 = dispatch(_pipe$1);
      return runtime_call(_pipe$2);
    }
  );
  return mouseUpEventListener(
    (_) => {
      let _pipe = new UserUnclicked();
      let _pipe$1 = dispatch(_pipe);
      return runtime_call(_pipe$1);
    }
  );
}
function init2(node_functions) {
  return [
    new Model(
      from_list(toList([])),
      toList([]),
      new$2(),
      get_window_size(),
      new ViewBox(new Vector(0, 0), get_window_size(), 1),
      new Navigator(new Vector(0, 0), false),
      new Normal(),
      new Vector(0, 0),
      new$5(node_functions),
      (() => {
        let _pipe = node_functions;
        let _pipe$1 = map(
          _pipe,
          (nf) => {
            return [lowercase2(nf.label), nf];
          }
        );
        return from_list(_pipe$1);
      })(),
      new$4(),
      from(0)
    ),
    none()
  ];
}
function none_effect_wrapper(model) {
  return [model, none()];
}
function simple_effect(msg) {
  return from2(
    (dispatch2) => {
      let _pipe = msg;
      return dispatch2(_pipe);
    }
  );
}
function user_added_node(model, node) {
  let _pipe = model.withFields({
    nodes: (() => {
      let _pipe2 = model.nodes;
      return insert(_pipe2, node.id, node);
    })()
  });
  return none_effect_wrapper(_pipe);
}
function user_unclicked_node(model) {
  let _pipe = model.withFields({
    navigator: model.navigator.withFields({ mouse_down: false })
  });
  return none_effect_wrapper(_pipe);
}
function user_clicked_node_output(model, node_id, offset) {
  let p1 = (() => {
    let _pipe2 = get_position(model.nodes, node_id);
    return add3(_pipe2, offset);
  })();
  let p2 = (() => {
    let _pipe2 = model.viewbox;
    return to_viewbox_translate(_pipe2, model.navigator.cursor_point);
  })();
  let id2 = generate_random_id("conn");
  let new_conn = new Conn(id2, p1, p2, node_id, "", "", "", true);
  let _pipe = model.connections;
  let _pipe$1 = prepend2(_pipe, new_conn);
  let _pipe$2 = ((c) => {
    return model.withFields({ connections: c });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function user_unclicked(model) {
  let _pipe = (() => {
    let $ = get_node_from_input_hovered(model.nodes);
    if (!$.isOk() && $[0] instanceof NotFound) {
      return model.connections;
    } else {
      let node = $[0][0];
      let input = $[0][1];
      let _pipe2 = model.connections;
      return map_active(
        _pipe2,
        (c) => {
          let $1 = c.source_node_id !== node.id;
          if (!$1) {
            return c;
          } else {
            return c.withFields({
              target_node_id: node.id,
              target_input_id: input_id(input),
              target_input_value: input_label(input),
              active: false
            });
          }
        }
      );
    }
  })();
  let _pipe$1 = filter(
    _pipe,
    (c) => {
      return c.target_node_id !== "" && c.active !== true;
    }
  );
  let _pipe$2 = unique(_pipe$1);
  let _pipe$3 = ((c) => {
    return model.withFields({ connections: c });
  })(
    _pipe$2
  );
  let _pipe$4 = sync_edges(_pipe$3);
  let _pipe$5 = recalc_graph(_pipe$4);
  return none_effect_wrapper(_pipe$5);
}
function user_clicked_conn(model, conn_id, event2) {
  let _pipe = model.connections;
  let _pipe$1 = map(
    _pipe,
    (c) => {
      let $ = c.id === conn_id;
      if (!$) {
        return c;
      } else {
        return c.withFields({
          p1: event2.position,
          target_node_id: "",
          target_input_id: "",
          active: true
        });
      }
    }
  );
  let _pipe$2 = ((conns) => {
    return model.withFields({ connections: conns });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function user_scrolled(model, delta_y) {
  let _pipe = model.viewbox;
  let _pipe$1 = update_zoom_level(_pipe, delta_y);
  let _pipe$2 = update_resolution(_pipe$1, model.window_resolution);
  let _pipe$3 = ((vb) => {
    return model.withFields({ viewbox: vb });
  })(_pipe$2);
  return none_effect_wrapper(_pipe$3);
}
function user_hover_node_input(model, input_id2) {
  let _pipe = model.nodes;
  let _pipe$1 = set_input_hover(_pipe, input_id2);
  let _pipe$2 = ((nodes) => {
    return model.withFields({ nodes });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function user_unhover_node_input(model) {
  let _pipe = model.nodes;
  let _pipe$1 = reset_input_hover(_pipe);
  let _pipe$2 = ((nodes) => {
    return model.withFields({ nodes });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function user_hover_node_output(model, output_id2) {
  let _pipe = model.nodes;
  let _pipe$1 = set_output_hover(_pipe, output_id2);
  let _pipe$2 = ((nodes) => {
    return model.withFields({ nodes });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function user_unhover_node_output(model) {
  let _pipe = model.nodes;
  let _pipe$1 = reset_output_hover(_pipe);
  let _pipe$2 = ((nodes) => {
    return model.withFields({ nodes });
  })(
    _pipe$1
  );
  return none_effect_wrapper(_pipe$2);
}
function graph_clear_selection(model) {
  let _pipe = model.withFields({ nodes_selected: new$2() });
  return none_effect_wrapper(_pipe);
}
function graph_add_node_to_selection(model, node_id) {
  let _pipe = model.withFields({
    nodes_selected: (() => {
      let _pipe2 = model.nodes_selected;
      return insert2(_pipe2, node_id);
    })()
  });
  return none_effect_wrapper(_pipe);
}
function graph_set_node_as_selection(model, node_id) {
  let _pipe = model.withFields({
    nodes_selected: (() => {
      let _pipe2 = new$2();
      return insert2(_pipe2, node_id);
    })()
  });
  return none_effect_wrapper(_pipe);
}
function graph_resize_view_box(model, resolution) {
  let _pipe = model.withFields({
    window_resolution: resolution,
    viewbox: update_resolution(model.viewbox, resolution)
  });
  return none_effect_wrapper(_pipe);
}
function graph_open_menu(model) {
  let _pipe = model.navigator.cursor_point;
  let _pipe$1 = ((_capture) => {
    return from_viewbox_scale(model.viewbox, _capture);
  })(_pipe);
  let _pipe$2 = ((cursor) => {
    return model.menu.withFields({ pos: cursor, active: true });
  })(_pipe$1);
  let _pipe$3 = ((menu) => {
    return model.withFields({ menu });
  })(
    _pipe$2
  );
  return none_effect_wrapper(_pipe$3);
}
function graph_close_menu(model) {
  let _pipe = model.menu.withFields({ active: false });
  let _pipe$1 = ((menu) => {
    return model.withFields({ menu });
  })(_pipe);
  return none_effect_wrapper(_pipe$1);
}
function graph_spawn_node(model, identifier) {
  let position = to_viewbox_space(model.viewbox, model.menu.pos);
  let _pipe = model.library;
  let _pipe$1 = new_node(_pipe, identifier, position);
  let _pipe$2 = ((res) => {
    if (res.isOk()) {
      let node = res[0];
      return model.withFields({ nodes: insert(model.nodes, node.id, node) });
    } else {
      return model;
    }
  })(_pipe$1);
  let _pipe$3 = sync_verts(_pipe$2);
  let _pipe$4 = recalc_graph(_pipe$3);
  return ((m) => {
    return [m, simple_effect(new GraphCloseMenu())];
  })(_pipe$4);
}
function graph_delete_selected_nodes(model) {
  let _pipe = model;
  let _pipe$1 = delete_selected_nodes(_pipe);
  let _pipe$2 = delete_orphaned_connections(_pipe$1);
  let _pipe$3 = sync_verts(_pipe$2);
  let _pipe$4 = sync_edges(_pipe$3);
  let _pipe$5 = recalc_graph(_pipe$4);
  return none_effect_wrapper(_pipe$5);
}
function graph_changed_connections(model) {
  let _pipe = model;
  return none_effect_wrapper(_pipe);
}
function update_last_clicked_point(model, event2) {
  let _pipe = event2.position;
  let _pipe$1 = ((_capture) => {
    return to_viewbox_space(model.viewbox, _capture);
  })(_pipe);
  return ((p2) => {
    return model.withFields({ last_clicked_point: p2 });
  })(
    _pipe$1
  );
}
function update_selected_nodes(event2, node_id) {
  return from2(
    (dispatch2) => {
      let _pipe = (() => {
        let $ = event2.shift_key_active;
        if ($) {
          return new GraphAddNodeToSelection(node_id);
        } else {
          return new GraphSetNodeAsSelection(node_id);
        }
      })();
      return dispatch2(_pipe);
    }
  );
}
function user_clicked_node(model, node_id, event2) {
  let _pipe = model.navigator;
  let _pipe$1 = set_navigator_mouse_down(_pipe);
  let _pipe$2 = ((nav) => {
    return model.withFields({
      navigator: nav,
      nodes: (() => {
        let _pipe$22 = model.nodes;
        return update_all_node_offsets(_pipe$22, nav.cursor_point);
      })()
    });
  })(_pipe$1);
  return ((m) => {
    return [
      m,
      batch(
        toList([
          update_selected_nodes(event2, node_id),
          simple_effect(new GraphCloseMenu())
        ])
      )
    ];
  })(_pipe$2);
}
function shift_key_check(event2) {
  return from2(
    (dispatch2) => {
      let _pipe = (() => {
        let $ = event2.shift_key_active;
        if ($) {
          return new GraphSetDragMode();
        } else {
          return new GraphClearSelection();
        }
      })();
      return dispatch2(_pipe);
    }
  );
}
function user_clicked_graph(model, event2) {
  let _pipe = model;
  let _pipe$1 = update_last_clicked_point(_pipe, event2);
  return ((m) => {
    return [
      m,
      batch(
        toList([shift_key_check(event2), simple_effect(new GraphCloseMenu())])
      )
    ];
  })(_pipe$1);
}
function key_pressed(key) {
  let $ = lowercase2(key);
  if ($ === "a") {
    return simple_effect(new GraphOpenMenu());
  } else if ($ === "backspace") {
    return simple_effect(new GraphDeleteSelectedNodes());
  } else if ($ === "delete") {
    return simple_effect(new GraphDeleteSelectedNodes());
  } else {
    return none();
  }
}
function user_pressed_key(model, key) {
  let _pipe = model;
  return ((m) => {
    return [m, key_pressed(key)];
  })(_pipe);
}
function translate(x, y) {
  let x_string = to_string3(x);
  let y_string = to_string3(y);
  return "translate(" + x_string + "," + y_string + ")";
}
function attr_viewbox(offset, resolution) {
  let _pipe = toList([offset.x, offset.y, resolution.x, resolution.y]);
  let _pipe$1 = map(_pipe, to_string3);
  let _pipe$2 = reduce(_pipe$1, (a, b) => {
    return a + " " + b;
  });
  return ((result) => {
    if (result.isOk()) {
      let res = result[0];
      return attribute("viewBox", res);
    } else {
      return attribute("viewBox", "0 0 100 100");
    }
  })(_pipe$2);
}
function view_node_input(input) {
  let id2 = input_id(input);
  let label = input_label(input);
  let hovered = input_hovered(input);
  return g(
    toList([
      attribute(
        "transform",
        (() => {
          let _pipe = input_position(input);
          return to_html(_pipe, new Translate());
        })()
      )
    ]),
    toList([
      circle(
        toList([
          attribute("cx", "0"),
          attribute("cy", "0"),
          attribute("r", "10"),
          attribute("fill", "currentColor"),
          attribute("stroke", "black"),
          (() => {
            if (hovered) {
              return attribute("stroke-width", "3");
            } else {
              return attribute("stroke-width", "0");
            }
          })(),
          class$("text-gray-500"),
          id(id2),
          on_mouse_enter(new UserHoverNodeInput(id2)),
          on_mouse_leave(new UserUnhoverNodeInput())
        ])
      ),
      text2(
        toList([
          attribute("x", "16"),
          attribute("y", "0"),
          attribute("font-size", "16"),
          attribute("dominant-baseline", "middle"),
          attribute("fill", "currentColor"),
          class$("text-gray-900")
        ]),
        label
      )
    ])
  );
}
function view_node_output(node) {
  let pos = output_position(node.output);
  let id2 = output_id(node.output);
  let hovered = output_hovered(node.output);
  let $ = node.id === "node.output";
  if (!$) {
    return g(
      toList([
        attribute(
          "transform",
          (() => {
            let _pipe = pos;
            return to_html(_pipe, new Translate());
          })()
        )
      ]),
      toList([
        circle(
          toList([
            attribute("cx", "0"),
            attribute("cy", "0"),
            attribute("r", "10"),
            attribute("fill", "currentColor"),
            attribute("stroke", "black"),
            (() => {
              if (hovered) {
                return attribute("stroke-width", "3");
              } else {
                return attribute("stroke-width", "0");
              }
            })(),
            class$("text-gray-500"),
            on_mouse_down(new UserClickedNodeOutput(node.id, pos)),
            on_mouse_enter(new UserHoverNodeOutput(id2)),
            on_mouse_leave(new UserUnhoverNodeOutput())
          ])
        )
      ])
    );
  } else {
    return none2();
  }
}
function view_grid_canvas(width, height) {
  let w = to_string3(width) + "%";
  let h = to_string3(height) + "%";
  let x = "-" + to_string3(divideInt(width, 2)) + "%";
  let y = "-" + to_string3(divideInt(height, 2)) + "%";
  return rect(
    toList([
      attribute("x", x),
      attribute("y", y),
      attribute("width", w),
      attribute("height", h),
      attribute("fill", "url(#grid)")
    ])
  );
}
function view_grid() {
  return defs(
    toList([]),
    toList([
      pattern(
        toList([
          id("smallGrid"),
          attribute("width", "8"),
          attribute("height", "8"),
          attribute("patternUnits", "userSpaceOnUse")
        ]),
        toList([
          path(
            toList([
              attribute("d", "M 8 0 L 0 0 0 8"),
              attribute("fill", "none"),
              attribute("stroke", "gray"),
              attribute("stroke-width", "0.5")
            ])
          )
        ])
      ),
      pattern(
        toList([
          id("grid"),
          attribute("width", "80"),
          attribute("height", "80"),
          attribute("patternUnits", "userSpaceOnUse")
        ]),
        toList([
          rect(
            toList([
              attribute("width", "80"),
              attribute("height", "80"),
              attribute("fill", "url(#smallGrid)")
            ])
          ),
          path(
            toList([
              attribute("d", "M 80 0 L 0 0 0 80"),
              attribute("fill", "none"),
              attribute("stroke", "gray"),
              attribute("stroke-width", "1")
            ])
          )
        ])
      )
    ])
  );
}
function mouse_event_decoder(e) {
  stop_propagation(e);
  return try$(
    field("shiftKey", bool)(e),
    (shift_key) => {
      return try$(
        mouse_position(e),
        (position) => {
          return new Ok(
            new MouseEvent(
              new Vector(round2(position[0]), round2(position[1])),
              shift_key
            )
          );
        }
      );
    }
  );
}
function view_node(node, selection) {
  let node_selected_class = (() => {
    let $ = contains2(selection, node.id);
    if ($) {
      return class$("text-gray-300 stroke-gray-400");
    } else {
      return class$("text-gray-300 stroke-gray-300");
    }
  })();
  let mousedown = (e) => {
    return try$(
      mouse_event_decoder(e),
      (decoded_event) => {
        return new Ok(new UserClickedNode(node.id, decoded_event));
      }
    );
  };
  return g(
    toList([
      id("g-" + node.id),
      attribute("transform", translate(node.position.x, node.position.y)),
      class$("select-none")
    ]),
    concat(
      toList([
        toList([
          rect(
            toList([
              id(node.id),
              attribute("width", "200"),
              attribute("height", "150"),
              attribute("rx", "25"),
              attribute("ry", "25"),
              attribute("fill", "currentColor"),
              attribute("stroke", "currentColor"),
              attribute("stroke-width", "2"),
              node_selected_class,
              on2("mousedown", mousedown),
              on_mouse_up(new UserUnclickedNode(node.id))
            ])
          ),
          text2(
            toList([
              attribute("x", "20"),
              attribute("y", "24"),
              attribute("font-size", "16"),
              attribute("fill", "currentColor"),
              class$("text-gray-900")
            ]),
            node.name
          ),
          view_node_output(node)
        ]),
        map(node.inputs, (input) => {
          return view_node_input(input);
        })
      ])
    )
  );
}
function view_connection(c) {
  let mousedown = (e) => {
    return try$(
      mouse_event_decoder(e),
      (decoded_event) => {
        return new Ok(new UserClickedConn(c.id, decoded_event));
      }
    );
  };
  return line(
    prepend(
      (() => {
        let $ = c.active;
        if ($) {
          return class$("text-gray-500");
        } else {
          return class$("text-gray-500 hover:text-indigo-500");
        }
      })(),
      prepend(
        attribute("stroke", "currentColor"),
        prepend(
          attribute("stroke-width", "10"),
          prepend(
            attribute("stroke-linecap", "round"),
            prepend(
              attribute("stroke-dasharray", "12,12"),
              prepend(
                on2("mousedown", mousedown),
                to_attributes(c)
              )
            )
          )
        )
      )
    )
  );
}
function keydown_event_decoder(e) {
  return try$(
    field("key", string)(e),
    (key) => {
      return new Ok(key);
    }
  );
}
function output_to_element(output2) {
  let decoders = any2(
    toList([
      string,
      (x) => {
        return map2(
          int(x),
          (o) => {
            return to_string3(o);
          }
        );
      },
      (x) => {
        return map2(
          float(x),
          (o) => {
            return to_string(o);
          }
        );
      }
    ])
  );
  let _pipe = decoders(from(output2));
  let _pipe$1 = ((res) => {
    if (res.isOk()) {
      let decoded = res[0];
      return decoded;
    } else {
      return "";
    }
  })(_pipe);
  return ((_capture) => {
    return attribute("dangerous-unescaped-html", _capture);
  })(
    _pipe$1
  );
}
function view_output_canvas(model) {
  return div(
    toList([
      class$(
        "w-80 h-80 absolute bottom-2 right-2 rounded border border-gray-300 bg-white flex items-center justify-center"
      ),
      output_to_element(model.output)
    ]),
    toList([])
  );
}
function view(model) {
  let user_moved_mouse$1 = (e) => {
    return try$(
      mouse_position(e),
      (pos) => {
        return new Ok(
          new UserMovedMouse(
            new Vector(round2(pos[0]), round2(pos[1]))
          )
        );
      }
    );
  };
  let mousedown = (e) => {
    return try$(
      mouse_event_decoder(e),
      (decoded_event) => {
        return new Ok(new UserClickedGraph(decoded_event));
      }
    );
  };
  let keydown = (e) => {
    return try$(
      keydown_event_decoder(e),
      (key) => {
        return new Ok(new UserPressedKey(key));
      }
    );
  };
  let wheel = (e) => {
    return try$(
      field("deltaY", float)(e),
      (delta_y) => {
        return new Ok(new UserScrolled(delta_y));
      }
    );
  };
  let spawn = (e) => {
    return try$(
      field("target", dynamic)(e),
      (target) => {
        return try$(
          field("id", string)(target),
          (identifier) => {
            return new Ok(new GraphSpawnNode(identifier));
          }
        );
      }
    );
  };
  return div(
    toList([attribute("tabindex", "0"), on2("keydown", keydown)]),
    toList([
      p(
        toList([class$("absolute right-2 top-2 select-none")]),
        toList([
          (() => {
            let $ = model.mode;
            if ($ instanceof Normal) {
              return text("NORMAL");
            } else {
              return text("DRAG");
            }
          })()
        ])
      ),
      svg(
        toList([
          id("graph"),
          attr_viewbox(model.viewbox.offset, model.viewbox.resolution),
          attribute("contentEditable", "true"),
          on2("mousemove", user_moved_mouse$1),
          on2("mousedown", mousedown),
          on_mouse_up(new GraphSetNormalMode()),
          on2("wheel", wheel)
        ]),
        toList([
          view_grid(),
          view_grid_canvas(500, 500),
          g(
            toList([]),
            (() => {
              let _pipe = model.connections;
              return map(_pipe, view_connection);
            })()
          ),
          g(
            toList([]),
            (() => {
              let _pipe = model.nodes;
              let _pipe$1 = map_to_list(_pipe);
              let _pipe$2 = map(_pipe$1, second);
              return map(
                _pipe$2,
                (node) => {
                  return view_node(node, model.nodes_selected);
                }
              );
            })()
          )
        ])
      ),
      view_menu(model.menu, spawn),
      view_output_canvas(model)
    ])
  );
}
var graph_limit = 500;
function user_moved_mouse(model, point) {
  let _pipe = model;
  let _pipe$1 = cursor_point(_pipe, point);
  let _pipe$2 = viewbox_offset(_pipe$1, graph_limit);
  let _pipe$3 = node_positions(_pipe$2);
  let _pipe$4 = dragged_connection(_pipe$3);
  let _pipe$5 = connections(_pipe$4);
  return none_effect_wrapper(_pipe$5);
}
function update(model, msg) {
  if (msg instanceof UserAddedNode) {
    let node = msg[0];
    return user_added_node(model, node);
  } else if (msg instanceof UserMovedMouse) {
    let point = msg[0];
    return user_moved_mouse(model, point);
  } else if (msg instanceof UserClickedNode) {
    let node_id = msg[0];
    let mouse_event = msg[1];
    return user_clicked_node(model, node_id, mouse_event);
  } else if (msg instanceof UserUnclickedNode) {
    return user_unclicked_node(model);
  } else if (msg instanceof UserClickedNodeOutput) {
    let node_id = msg[0];
    let offset = msg[1];
    return user_clicked_node_output(model, node_id, offset);
  } else if (msg instanceof UserUnclicked) {
    return user_unclicked(model);
  } else if (msg instanceof UserClickedConn) {
    let conn_id = msg[0];
    let mouse_event = msg[1];
    return user_clicked_conn(model, conn_id, mouse_event);
  } else if (msg instanceof UserClickedGraph) {
    let mouse_event = msg[0];
    return user_clicked_graph(model, mouse_event);
  } else if (msg instanceof UserScrolled) {
    let delta_y = msg[0];
    return user_scrolled(model, delta_y);
  } else if (msg instanceof UserHoverNodeInput) {
    let input_id2 = msg[0];
    return user_hover_node_input(model, input_id2);
  } else if (msg instanceof UserUnhoverNodeInput) {
    return user_unhover_node_input(model);
  } else if (msg instanceof UserHoverNodeOutput) {
    let output_id2 = msg[0];
    return user_hover_node_output(model, output_id2);
  } else if (msg instanceof UserUnhoverNodeOutput) {
    return user_unhover_node_output(model);
  } else if (msg instanceof UserPressedKey) {
    let key = msg[0];
    return user_pressed_key(model, key);
  } else if (msg instanceof GraphClearSelection) {
    return graph_clear_selection(model);
  } else if (msg instanceof GraphSetDragMode) {
    let _pipe = model.withFields({ mode: new Drag() });
    return none_effect_wrapper(_pipe);
  } else if (msg instanceof GraphSetNormalMode) {
    let _pipe = model.withFields({ mode: new Normal() });
    return none_effect_wrapper(_pipe);
  } else if (msg instanceof GraphAddNodeToSelection) {
    let node_id = msg[0];
    return graph_add_node_to_selection(model, node_id);
  } else if (msg instanceof GraphSetNodeAsSelection) {
    let node_id = msg[0];
    return graph_set_node_as_selection(model, node_id);
  } else if (msg instanceof GraphResizeViewBox) {
    let resolution = msg[0];
    return graph_resize_view_box(model, resolution);
  } else if (msg instanceof GraphOpenMenu) {
    return graph_open_menu(model);
  } else if (msg instanceof GraphCloseMenu) {
    return graph_close_menu(model);
  } else if (msg instanceof GraphSpawnNode) {
    let identifier = msg[0];
    return graph_spawn_node(model, identifier);
  } else if (msg instanceof GraphDeleteSelectedNodes) {
    return graph_delete_selected_nodes(model);
  } else {
    return graph_changed_connections(model);
  }
}
function main() {
  let nodes = math_nodes();
  let app$1 = application(init2, update, view);
  let $ = start3(app$1, "#app", nodes);
  if (!$.isOk()) {
    throw makeError(
      "assignment_no_match",
      "nodework",
      93,
      "main",
      "Assignment pattern did not match",
      { value: $ }
    );
  }
  let send_to_runtime = $[0];
  setup(send_to_runtime);
  return void 0;
}

// build/.lustre/entry.mjs
main();
