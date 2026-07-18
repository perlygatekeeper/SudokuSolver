# Benchmarking

## Overview

SudokuSolver includes benchmark support so releases can measure solver
capability against stable puzzle collections.

The default bundled benchmark target is a small example puzzle file:

```text
Puzzles/Puzzle_Dispatch_20191209.txt
```

This collection is intentionally small enough to run quickly from a reduced
checkout. Larger benchmark corpora can still be supplied explicitly when you
have them available outside the repository.

---

## Make Targets

Run the bundled solver benchmark:

```bash
perl -Ilib ./bin/sudoku.pl --benchmark Puzzles/Puzzle_Dispatch_20191209.txt
```

Run the canonicalization timing benchmark:

```bash
make canonical-benchmark
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

Benchmark output should be captured before each release. When the historical
first-50 benchmark corpus is available outside the reduced checkout, the
project goal remains:

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
