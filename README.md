# 🎄 Advent of Code 2026

Solutions for [Advent of Code](https://adventofcode.com/) in [Lean 4](https://lean-lang.org/).

## Benchmarks

<!--- benchmarking table --->

<!--- benchmarking table --->

## Usage

No dependencies beyond the Lean toolchain pinned in `lean-toolchain`.

```text
Aoc/Basic.lean    Solution type, a `lines` helper, the `#examples` command
Aoc/Runner.lean   running, timing, benchmarking, README table
Aoc.lean          imports both
Days/DayNN.lean   model for a new day
Days/Day01.lean   one file per day
Main.lean         imports the days and lists them in `days`
examples/         examples from the puzzle text, as dayNN.txt or dayNN-1.txt, dayNN-2.txt, ...
data/             puzzle inputs (git-ignored)
```

### Every day

Replace `02` with the day.

1. Download the input with [aoc-cli](https://github.com/scarvalhojr/aoc-cli):

   ```sh
   aoc download -y 2026 -d 2 -I -i data/day02.txt
   ```

2. Save each example from the puzzle text in `examples/`: `day02.txt`, or `day02-1.txt`,
   `day02-2.txt`, ... when there are several.

3. Create the day from the model:

   ```sh
   sed 's/NN/02/g' Days/DayNN.lean > Days/Day02.lean
   ```

   Then write `parse`, `part1`, `part2`, and list the examples of each part with their answers,
   as many per part as the puzzle gives:

   ```lean
   #examples part1
     "day02-1" => 5
     "day02-2" => 8

   #examples part2
     "day02-3" => 2
   ```

4. Register it in `Main.lean`: add `import Days.Day02` at the top and `(2, Day02.solution)` to
   `days`.

5. Build and run:

   ```sh
   lake build                              # also checks the examples
   lake exe solve 2                        # reads data/day02.txt, prints answers and times
   lake exe solve 2 examples/day02-1.txt   # any other input
   ```

A wrong example answer fails the build with an error on its line, such as
`day02-2: part1 returned 7, expected 8`, and the editor flags it as you type. Editing a file in
`examples/` also triggers a rebuild, so the checks never go stale.

### Benchmarks

```sh
lake exe solve bench      # every day: rebuilds the table
lake exe solve bench 2    # one day: updates its row, keeps the others
```

Each day runs as many times as fit in one second (at most 1000), and the table above gets the
mean times for parsing, part 1 and part 2. The total is the sum of the Total column.
