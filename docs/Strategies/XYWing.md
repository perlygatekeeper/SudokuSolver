# XY-Wing

## Overview

A bivalue pivot {X,Y} sees two bivalue pincers {X,Z} and {Y,Z}. Any cell that sees both pincers cannot contain Z.

## Solver Contract

The strategy inspects the grid without modifying it and returns `Sudoku::Deduction` objects for candidate eliminations.

## Testing

The test suite includes a positive pattern, a negative near-pattern, deduction explanation checks, and application checks.
