export function documentResizeEventListener(listener) {
  return window.addEventListener("resize", listener)
}

export function windowSize() {
  return [window.innerWidth, window.innerHeight]
}
