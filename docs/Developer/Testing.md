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

Regression tests are different from strategy tests. A strategy test should isolate one technique. A regression test should exercise the solver as a user would: provide a puzzle, run the solver, and verify the final result.

The 90-series test files should prefer durable public outcomes, such as final grid values and solved status, over fragile implementation details such as pass counts or the exact order in which strategies fire.

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

## Basic Strategy Tests

Basic strategy tests cover one solving technique per file:

* `40_naked_singles.t` covers Naked Singles.
* `41_hidden_singles.t` covers Hidden Singles.
* `42_pointing_claiming.t` covers Pointing / Claiming.

Strategy tests should focus on public strategy behavior: the reported progress, the cells solved or candidates removed, and any candidate cleanup caused by the strategy. They should not depend on temporary local variables or internal counting structures unless those structures become part of a documented public contract.

## Intermediate Strategy Tests

Intermediate strategy tests cover techniques that depend on candidate patterns rather than immediate singles:

* `50_naked_pairs.t` covers Naked Pairs.
* `51_hidden_pairs.t` covers Hidden Pairs.

These tests should use deliberately constructed candidate grids so each strategy can be tested in isolation. When a legacy strategy has a known defect, prefer documenting it with a TODO test rather than hiding the defect or changing the test to match the bug permanently.

## Advanced Strategy Tests

Advanced strategy tests cover techniques that depend on larger candidate patterns or chained reasoning:

* `60_x_wings.t` covers X-Wing.
* `61_remote_pairs.t` records the current legacy Remote Pairs behavior.

When an advanced strategy is known to be experimental or historically incomplete, tests should make that status clear. Prefer documenting the current behavior and the intended future repair rather than silently treating incomplete legacy behavior as final design.
