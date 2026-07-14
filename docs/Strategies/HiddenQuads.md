# Hidden Quads

## Overview

A Hidden Quad occurs when four candidates appear only in the same four cells of a row, column, or box.

Those four cells must contain those four values, so every other candidate can be removed from the four cells.

## Example

If candidates `{1,3,6,9}` occur only in `R1C1`, `R1C3`, `R1C5`, and `R1C7`, then all other candidates may be removed from those four cells.

## Implementation Contract

`Sudoku::Strategy::HiddenQuads` discovers deductions only. It does not modify the grid directly.

The shared subset search lives in `Sudoku::Subset`.

## Test

```text
t/225_hidden_quads.t
```
