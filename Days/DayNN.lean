import Aoc.Basic

namespace Aoc.DayNN

/-- The puzzle input, parsed. Change the type to whatever fits the day. -/
def parse (input : String) : List String :=
  lines input

def part1 (_rows : List String) : Nat :=
  0

def part2 (_rows : List String) : Nat :=
  0

def solution : Solution := .of parse part1 part2

/-! Examples from the puzzle text, in `examples/`: `dayNN.txt`, or `dayNN-1.txt`, `dayNN-2.txt`,
... when there are several. One line per example, with the answer the puzzle gives. -/

#examples part1
  "dayNN" => 0

#examples part2
  "dayNN" => 0

end Aoc.DayNN
