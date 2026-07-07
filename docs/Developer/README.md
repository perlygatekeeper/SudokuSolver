# SudokuSolver Developer Notes

This directory records design rationale, internal contracts, and development plans.

These notes are not user-facing documentation. They exist so future development can preserve the intent of the codebase while the implementation changes.

## Current Documents

* `Architecture.md` — why the project is being separated into script, solver, grid, and strategies.
* `SolverContract.md` — responsibilities and boundaries for `Solver.pm`.
* `StrategyContract.md` — expected future interface for solving strategies.
* `Testing.md` — testing structure and conventions.

## Guiding Rule

When code structure changes, update these documents if the intent, responsibility boundaries, or contracts change.
