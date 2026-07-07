# Testing Notes

The project test suite should make refactoring safe.

## Canonical Check Command

Use one command as the normal project health check:

```bash
make PERL=perl check
```

Use narrower commands only when isolating a failure.

## Test Support

Reusable test helpers should live in:

lib/Sudoku/Test.pm

This module is for test convenience and shared project test behavior. It may provide helpers for loading puzzles, running solvers, comparing grids, and checking output.

Do not create test abstractions before they are useful. Add helpers when multiple tests need the same setup or assertion behavior.

## Test Groups

Suggested naming convention:

00  Project integrity
10  Cell
20  Grid
30  Solver
40  Basic solving strategies
50  Intermediate solving strategies
60  Advanced solving strategies
90  Regression tests

## Regression Tests

Known puzzle and solution pairs should become regression tests. The goal is to preserve current solver behavior while the internal architecture changes.

When a refactor changes output format intentionally, update the regression tests and document the reason.
