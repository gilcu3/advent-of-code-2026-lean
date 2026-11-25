import Aoc
-- One import per day, for example:
-- import Days.Day01

open Aoc

/-- One line per day, for example `(1, Day01.solution)`. -/
def days : List (Nat × Solution) := [
]

def main (args : List String) : IO UInt32 :=
  cli days args
