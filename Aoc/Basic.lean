namespace Aoc

/-- A day: a parser, and two parts that take the parsed input and return the answer as text.
Parsing is separate so the benchmarks can time it on its own. -/
structure Solution where
  Input : Type
  parse : String → Input
  part1 : Input → String
  part2 : Input → String

/-- Builds a `Solution` from a parser and two parts whose results can be printed. -/
def Solution.of {α β γ : Type} [ToString β] [ToString γ]
    (parse : String → α) (part1 : α → β) (part2 : α → γ) : Solution where
  Input := α
  parse := parse
  part1 := toString ∘ part1
  part2 := toString ∘ part2

/-- The non-empty lines of the input. -/
def lines (input : String) : List String :=
  (input.splitOn "\n").filter (!·.isEmpty)

end Aoc

/-- Checks a part on example files from `examples/`, one `"name" => answer` per line:

```
#examples part1
  "day10-1" => 4
  "day10-2" => 8
```

Each file goes through the day's `parse` and then the part. A wrong answer fails the build,
with an error on its line that shows what the part returned. -/
syntax "#examples " ident (ppLine withPosition(str " => " term))+ : command

open Lean in
macro_rules
  | `(#examples $part:ident $[$names:str => $answers]*) => do
    let mut checks := #[]
    for name in names, answer in answers do
      let file := (Syntax.isStrLit? name).getD ""
      let path := Syntax.mkStrLit s!"../examples/{file}.txt"
      let label := Syntax.mkStrLit s!"{file}: {part.getId} returned "
      checks := checks.push (← withRef name `(#eval show IO Unit from do
        let got := toString ($part ($(mkIdent `parse) (include_str $path)))
        let want := toString $answer
        unless got == want do throw <| IO.userError ($label ++ got ++ ", expected " ++ want)))
    return mkNullNode checks
