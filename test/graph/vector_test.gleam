import gleeunit/should
import nodework/vector.{Vector}

pub fn subtract__test() {
  Vector(0, 0)
  |> vector.subtract(Vector(5, 5))
  |> should.equal(Vector(5, 5))
}

pub fn subtract__minus__test() {
  Vector(-1, -1)
  |> vector.subtract(Vector(-2, -2))
  |> should.equal(Vector(-1, -1))
}

pub fn add__test() {
  Vector(1, 1)
  |> vector.add(Vector(5, 5))
  |> should.equal(Vector(6, 6))
}

pub fn add__minus__test() {
  Vector(-1, -1)
  |> vector.add(Vector(5, 5))
  |> should.equal(Vector(4, 4))
}

pub fn get_path__test() {
  Vector(10, 10)
  |> vector.get_path(Vector(20, 20))
  |> should.equal("M 10 10 C 15 10, 15 20, 20 20")
}
