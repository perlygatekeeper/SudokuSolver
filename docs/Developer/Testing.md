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

## Test Responsibilities

Each test file should verify one public responsibility.

Tests should avoid depending on implementation details whenever practical. If a refactor changes the implementation but preserves public behavior, the relevant tests should continue to pass without modification.

When a public interface changes intentionally, update the tests to reflect the new contract and document the reason in the appropriate developer note or release note.

## Solver Tests

Solver tests are divided by responsibility:

* `30_solver_options.t` covers puzzle input normalization and option handling.
* `31_solver_api.t` covers the public `Solver` object interface.
* `32_solver_execution.t` covers the solve lifecycle at a high level.

Strategy-specific behavior should not be tested in the solver test group. Those tests belong in the later strategy-numbered groups.
