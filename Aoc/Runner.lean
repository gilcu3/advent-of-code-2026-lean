import Aoc.Basic

namespace Aoc

/-- `7` → `"07"`, for file names. -/
def pad2 (n : Nat) : String :=
  if n < 10 then s!"0{n}" else toString n

/-- The input file of a day, as `data/day07.txt`. -/
def inputPath (day : Nat) : System.FilePath :=
  s!"data/day{pad2 day}.txt"

/-- Evaluates `f`. As an opaque `IO` action it cannot be moved past the clock reads around it. -/
@[noinline] def eval (f : Unit → α) : IO α :=
  pure (f ())

/-- Runs `f` and returns its result with the elapsed nanoseconds. -/
def timed (f : Unit → α) : IO (α × Nat) := do
  let start ← IO.monoNanosNow
  let a ← eval f
  return (a, (← IO.monoNanosNow) - start)

/-- Nanoseconds in the largest fitting unit with three decimals, as `66.571 us`. -/
def fmtTime (ns : Nat) : String :=
  let (unit, name) :=
    if ns < 1000 then (1, "ns")
    else if ns < 1000000 then (1000, "us")
    else if ns < 1000000000 then (1000000, "ms")
    else (1000000000, "s")
  let frac := ns % unit * 1000 / unit
  let zeros := if frac < 10 then "00" else if frac < 100 then "0" else ""
  s!"{ns / unit}.{zeros}{frac} {name}"

structure Times where
  parse : Nat
  part1 : Nat
  part2 : Nat

def Times.total (t : Times) : Nat :=
  t.parse + t.part1 + t.part2

/-- One run of a day: both answers and the time of each step. -/
def runOnce (s : Solution) (input : String) : IO (String × String × Times) := do
  let (x, parse) ← timed fun _ => s.parse input
  let (a1, part1) ← timed fun _ => s.part1 x
  let (a2, part2) ← timed fun _ => s.part2 x
  return (a1, a2, { parse, part1, part2 })

/-- Prints the answers of a day with the time each step took. -/
def solve (s : Solution) (file : System.FilePath) : IO Unit := do
  let (a1, a2, t) ← runOnce s (← IO.FS.readFile file)
  IO.println s!"Parsing: ({fmtTime t.parse})"
  IO.println s!"Part 1: {a1} ({fmtTime t.part1})"
  IO.println s!"Part 2: {a2} ({fmtTime t.part2})"

/-- Mean times of a day over as many runs as fit in one second (at least 1, at most 1000). -/
def benchDay (s : Solution) (input : String) : IO Times := do
  let start ← IO.monoNanosNow
  let mut sum : Times := ⟨0, 0, 0⟩
  let mut runs := 0
  repeat
    let (_, _, t) ← runOnce s input
    sum := ⟨sum.parse + t.parse, sum.part1 + t.part1, sum.part2 + t.part2⟩
    runs := runs + 1
    if runs ≥ 1000 || (← IO.monoNanosNow) - start ≥ 1000000000 then break
  return ⟨sum.parse / runs, sum.part1 / runs, sum.part2 / runs⟩

/-- The inverse of `fmtTime`, to three decimals: `66.571 us` → `66571`. -/
def parseTime (s : String) : Option Nat := do
  let [num, name] := (s.splitOn " ").filter (!·.isEmpty) | none
  let unit ← [("ns", 1), ("us", 1000), ("ms", 1000000), ("s", 1000000000)].lookup name
  let [whole, frac] := num.splitOn "." | none
  return (whole.toNat?.getD 0 * 1000 + frac.toNat?.getD 0) * unit / 1000

def row (day : Nat) (t : Times) : String :=
  s!"| [Day {day}](./Days/Day{pad2 day}.lean) | {fmtTime t.parse} | {fmtTime t.part1} " ++
  s!"| {fmtTime t.part2} | {fmtTime t.total} |"

/-- The day of a table row, from its `[Day 7]` link. -/
def rowDay (line : String) : Option Nat := do
  let [_, rest] := line.splitOn "[Day " | none
  (← (rest.splitOn "]").head?).toNat?

/-- The total time of a table row, from its last column. -/
def rowTotal (line : String) : Nat :=
  ((line.splitOn "|")[5]? >>= parseTime).getD 0

def marker := "<!--- benchmarking table --->"

/-- The rows of the table in `README.md`, by day. -/
def readRows : IO (List (Nat × String)) := do
  let [_, table, _] := (← IO.FS.readFile "README.md").splitOn marker | return []
  return (table.splitOn "\n").filterMap fun line => (rowDay line).map (·, line)

/-- Prints the table and writes it between the two markers in `README.md`. -/
def writeRows (rows : List (Nat × String)) : IO Unit := do
  let rows := (rows.mergeSort (·.1 ≤ ·.1)).map (·.2)
  let total := rows.foldl (· + rowTotal ·) 0
  let table := "\n".intercalate (
    "| Day | Parsing | Part 1 | Part 2 | Total |" ::
    "| :-- | ------: | -----: | -----: | ----: |" :: rows) ++ s!"\n\n**Total:** {fmtTime total}"
  IO.println table
  match (← IO.FS.readFile "README.md").splitOn marker with
  | [before, _, after] =>
    IO.FS.writeFile "README.md" s!"{before}{marker}\n\n{table}\n\n{marker}{after}"
    IO.println "Updated README.md"
  | _ => IO.eprintln s!"README.md needs exactly two `{marker}` lines"

/-- Benchmarks the given days that have an input file and updates their rows in the README.
The other rows stay unless `fresh`, which starts the table over. -/
def bench (days : List (Nat × Solution)) (fresh : Bool) : IO Unit := do
  let mut rows ← if fresh then pure [] else readRows
  for (day, s) in days do
    let file := inputPath day
    unless ← file.pathExists do
      IO.eprintln s!"Day {day}: skipped, {file} not found"
      continue
    let t ← benchDay s (← IO.FS.readFile file)
    rows := (day, row day t) :: rows.filter (·.1 != day)
  writeRows rows

def usage : IO UInt32 := do
  IO.eprintln "usage: lake exe solve <day> [input-file]\n       lake exe solve bench [day]"
  return 1

/-- The command line of `lake exe solve`. -/
def cli (days : List (Nat × Solution)) (args : List String) : IO UInt32 := do
  let find (day : String) : Option (Nat × Solution) :=
    match day.toNat? with
    | some n => (days.lookup n).map (n, ·)
    | none => none
  let unknown (day : String) : IO UInt32 := do
    IO.eprintln s!"Unknown day {day}: add it to `days` in Main.lean"; return 1
  match args with
  | ["bench"] => bench days true; return 0
  | ["bench", day] =>
    let some d := find day | unknown day
    bench [d] false; return 0
  | [day] | [day, _] =>
    let some (n, s) := find day | unknown day
    solve s ⟨args[1]?.getD (inputPath n).toString⟩
    return 0
  | _ => usage

end Aoc
