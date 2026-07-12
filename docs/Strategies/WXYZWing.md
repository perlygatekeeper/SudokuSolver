# WXYZ-Wing

## Overview

This implementation recognizes the conservative classic form: a four-candidate pivot and three bivalue pincers {W,Z}, {X,Z}, and {Y,Z}. A cell seeing all four pattern cells cannot contain Z.

## Solver Contract

The strategy inspects the grid without modifying it and returns `Sudoku::Deduction` objects for candidate eliminations.

## Testing

The test suite includes a positive pattern, a negative near-pattern, deduction explanation checks, and application checks.
