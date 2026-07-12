# XYZ-Wing

## Overview

A trivalue pivot {X,Y,Z} sees pincers {X,Z} and {Y,Z}. Any cell that sees the pivot and both pincers cannot contain Z.

## Solver Contract

The strategy inspects the grid without modifying it and returns `Sudoku::Deduction` objects for candidate eliminations.

## Testing

The test suite includes a positive pattern, a negative near-pattern, deduction explanation checks, and application checks.
