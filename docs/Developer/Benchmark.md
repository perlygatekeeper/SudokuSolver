# Benchmarking

## Overview

SudokuSolver includes benchmark support so releases can measure solver
capability against stable puzzle collections.

The first benchmark target is the first 50 canonical 17-clue puzzles:

```text
Puzzles/sudoku17-first50.txt
```

This collection is useful because it is small enough to run frequently and
hard enough to expose gaps in the current strategy set.

---

## Make Targets

Run the default benchmark:

```bash
make benchmark
```

Run the canonical first-50 benchmark explicitly:

```bash
make benchmark-first50
```

Both currently run:

```bash
perl -Ilib ./bin/sudoku.pl --benchmark Puzzles/sudoku17-first50.txt
```

---

## Command-Line Interface

The benchmark runner is exposed through:

```bash
bin/sudoku.pl --benchmark FILE
```

The benchmark command processes every puzzle in the file and prints a summary.

---

## Reported Values

The benchmark reports:

- puzzles processed
- solved puzzles
- stalled puzzles
- contradictions
- average solve time
- total solve time
- highest strategy usage
- per-strategy contribution totals
- unsolved puzzle indexes

---

## Release Use

Benchmark output should be captured before each release.

The project goal for the canonical first-50 benchmark is:

```text
Solve all 50 puzzles without guessing.
```

Current known baseline before additional strategy expansion:

```text
Solved: 41 / 50
```

Future strategies should improve benchmark coverage without introducing
regressions.

## Strategy Contributions

The benchmark reports every registered strategy, including strategies that made
no deductions. For each strategy it records:

- puzzles used: puzzles in which the strategy made at least one deduction
- deductions: total applied deductions
- cells: `set_value` deductions
- eliminations: `remove_candidate` deductions

This table shows whether a newly added strategy contributes even when it does
not change the final solved-puzzle count.
