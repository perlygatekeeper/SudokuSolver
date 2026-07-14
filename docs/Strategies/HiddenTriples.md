# Hidden Triples

## Overview

A Hidden Triple occurs when three candidate values can appear only in the same three cells of a row, column, or box.

Those three cells must contain the three values, so every other candidate can be removed from them.

## Example

If candidates 2, 5, and 8 occur only in `R1C1`, `R1C4`, and `R1C7`, those cells may be reduced to `{2,5,8}`.

## Implementation Contract

`Sudoku::Strategy::HiddenTriples` discovers deductions only. It does not modify the grid directly.

The shared subset search lives in `Sudoku::Subset`.

## Test

```text
t/223_hidden_triples.t
```
