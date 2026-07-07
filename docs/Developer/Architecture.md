# Architecture Rationale

SudokuSolver is being restored as a logic-first Sudoku solver. The primary architectural goal is to separate representation, orchestration, solving techniques, and command-line behavior.

## Why Separate the Pieces?

The legacy project works, but much of the behavior lives in large modules and scripts. That makes it harder to test individual concepts and harder to extend the solver safely.

The project should move toward this shape:

```text
bin/sudoku.pl
    command-line interface only

Solver.pm
    puzzle loading and solve orchestration

Grid.pm
    board representation and candidate state

Strategy::*
    individual solving techniques
```

The command-line script should not know how solving works. It should parse user input, create a solver, run it, and print results.

The solver should not directly encode every solving technique forever. Initially it may call existing `Grid` methods, but over time it should delegate to strategy modules.

The grid should represent the puzzle and expose safe operations for reading cells, setting values, and eliminating candidates. It should gradually stop owning high-level strategy logic.

## Why Preserve Behavior First?

The project already contains useful solving logic. Early cleanup should preserve existing behavior while improving structure. A behavior-preserving refactor is safer than adding features while moving code.

For v0.5.x, prefer small patches that:

* keep `make check` passing,
* do not introduce new solving techniques,
* preserve existing output unless the patch explicitly changes output,
* make later tests and refactors easier.

## Long-Term Direction

Eventually each solving strategy should be explainable. A strategy should not merely change the grid; it should also be able to report what it changed and why the deduction is valid.

That design supports future features such as hint mode, explain mode, strategy statistics, and difficulty estimation.
