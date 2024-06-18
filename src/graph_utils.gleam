import gleam/int.{to_string}
import gleam/string

pub type Position {
  Position(x: Int, y: Int)
}

// export function getPath(startPoint, endPoint) {
//   const xHalfwayDiff = Math.abs(startPoint.x - endPoint.x) * 0.5;

//   return `M ${startPoint.x} ${startPoint.y} C ${startPoint.x + xHalfwayDiff} ${startPoint.y}, ${endPoint.x - xHalfwayDiff} ${endPoint.y}, ${endPoint.x} ${endPoint.y}`;
// }

// export function getTranslation(transform) {
//   return {
//     x: transform.baseVal[0].matrix.e,
//     y: transform.baseVal[0].matrix.f,
//   };
// }

// export function nodeOffset(el, svgPoint) {
//   const initialTranslation = getTranslation(el.transform);
//   const p = {
//     x: svgPoint.x - initialTranslation.x,
//     y: svgPoint.y - initialTranslation.y,
//   };
//   return p;
// }

// export function translateNode(startPoint, currentPoint, offset) {
//   const diffX = currentPoint.x - startPoint.x;
//   const diffY = currentPoint.y - startPoint.y;

//   return {
//     x: startPoint.x + diffX - offset.x,
//     y: startPoint.y + diffY - offset.y,
//   };
// }

// export function getSVGPoint(svg, event) {
//   let p = new DOMPoint(event.clientX, event.clientY);

//   return p.matrixTransform(svg.getScreenCTM().inverse());
// }

pub fn translate_node(
  start_point: Position,
  current_point: Position,
  offset: Position,
) -> Position {
  let diff_x = current_point.x - start_point.x
  let diff_y = current_point.y - start_point.y

  Position(
    x: start_point.x + diff_x - offset.x,
    y: start_point.y + diff_y - offset.y,
  )

  Position(
    x: current_point.x - offset.x,
    y: current_point.y - offset.y
  )
}

pub fn get_path(start_point: Position, end_point: Position) -> String {
  let halfway_diff = int.absolute_value(start_point.x - end_point.y) / 2

  string.concat([
    "M ",
    to_string(start_point.x),
    " ",
    to_string(start_point.y),
    " C ",
    to_string(start_point.x + halfway_diff),
    " ",
    to_string(start_point.y),
    ", ",
    to_string(end_point.x - halfway_diff),
    " ",
    to_string(end_point.y),
    ", ",
    to_string(end_point.x),
    " ",
    to_string(end_point.y),
  ])
}
