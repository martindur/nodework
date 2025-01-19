
export function saveToLocalStorage(key, data) {
  localStorage.setItem(key, data)
}

export function getFromLocalStorage(key) {
  const item = localStorage.getItem(key);
  if (item) return item;

  return "";
}
