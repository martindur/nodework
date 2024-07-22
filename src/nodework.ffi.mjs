
export function documentResizeEventListener(listener) {
  return window.addEventListener("resize", listener)
}

export function mouseUpEventListener(listener) {
  return window.addEventListener("mouseup", listener)
}

export function windowSize() {
  return [window.innerWidth, window.innerHeight]
}

