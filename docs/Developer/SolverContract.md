# Solver Contract

`Solver.pm` is intended to become the orchestration layer for SudokuSolver.

## Responsibilities

`Solver` should own:

* selecting and loading a puzzle,
* constructing the `Grid`,
* running the solve loop,
* deciding which strategies run and in what order,
* reporting whether progress was made,
* exposing the solved or partially solved grid to callers.

## Non-Responsibilities

`Solver` should not own:

* command-line parsing,
* low-level cell storage,
* row/column/box membership calculations,
* direct printing/layout logic,
* the internal implementation of each solving technique.

Some of those responsibilities may still exist in legacy code during v0.5.x. Moving them out should be done gradually and with tests.

## Near-Term v0.5.x Contract

During the v0.5.x cleanup, `Solver` may call existing `Grid` methods directly. That is acceptable as an intermediate step.

A reasonable transitional API is:

```perl
my $solver = Solver->new(
    file   => $file,
    puzzle => $puzzle,
);

$solver->load;
$solver->solve;
$solver->grid->big_print;
```

The exact names may change, but the direction should remain: the script creates and invokes a solver; it does not contain solving logic.

## Success Criteria

The command-line script should eventually be thin enough that most behavior can be tested without running the script itself.
