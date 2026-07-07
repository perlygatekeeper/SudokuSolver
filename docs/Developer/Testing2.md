# Testing Strategy

## Overview

SudokuSolver's test suite is organized by project architecture.

The numbering scheme is intended to make the test layout readable and scalable as the project grows.

---

## Test Numbering

00  Project integrity

10  Cell

20  Grid

30  Solver

40  Basic solving strategies

50  Intermediate solving strategies

60  Advanced solving strategies

70  Symmetry and canonicalization

80  Difficulty rating

90  Regression tests

---

## Current Test Groups

### 00 — Project Integrity

Tests that the project loads and the version is available.

Example:

00_load.t

---

### 10 — Cell

Tests the behavior of individual cells.

Examples:

10_cell.t
11_cell_validation.t
12_cell_output.t

---

### 20 — Grid

Tests the board representation.

Examples:

20_grid.t
21_grid_load.t
22_grid_units.t
23_grid_output.t

---

### 30 — Solver

Tests the public Solver object and its lifecycle.

Examples:

30_solver_options.t
31_solver_api.t
32_solver_execution.t

---

### 40 — Basic Strategies

Tests techniques that are commonly considered basic.

Examples:

40_naked_singles.t
41_hidden_singles.t
42_pointing_claiming.t

---

### 50 — Intermediate Strategies

Tests pair-based strategies.

Examples:

50_naked_pairs.t
51_hidden_pairs.t

---

### 60 — Advanced Strategies

Tests more complex pattern or chain-based strategies.

Examples:

60_x_wings.t
61_remote_pairs.t

---

### 70 — Symmetry and Canonicalization

Reserved for future tests involving puzzle equivalence.

Possible examples:

70_symmetry_transforms.t
71_digit_normalization.t
72_canonicalization.t
73_equivalence.t

---

### 80 — Difficulty Rating

Reserved for future tests involving difficulty scoring.

Possible examples:

80_difficulty_basic.t
81_difficulty_weighted.t
82_difficulty_strategy_counts.t
83_difficulty_regressions.t

---

### 90 — Regression Tests

End-to-end tests based on known puzzles and known outputs.

Examples:

90_regression_known_solution.t

Regression tests should avoid depending on a specific internal strategy sequence unless that sequence is itself the behavior under test.

---

## Test Philosophy

Each test file should verify one public responsibility.

Tests should avoid depending on implementation details whenever practical.

If a refactor changes the implementation but preserves the public behavior, the test should continue to pass without modification.

When a public interface changes intentionally, the tests should be updated to reflect the new contract.

---

## What Good Tests Should Do

Good tests should:

- be deterministic
- be easy to understand
- test one responsibility
- fail clearly
- avoid unnecessary output
- avoid relying on unrelated behavior
- document the intended contract

---

## What Tests Should Avoid

Tests should avoid:

- testing private implementation details
- depending on incidental output formatting unless testing output
- using large puzzles when a small controlled setup is enough
- requiring internet access
- requiring user-specific paths
- depending on execution order between test files

---

## Project Health Command

The primary health command is:

make check

This should run syntax checks and the test suite.

When possible, every commit should leave this command passing.
