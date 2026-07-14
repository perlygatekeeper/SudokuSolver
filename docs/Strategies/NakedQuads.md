# Naked Quads

## Overview

A Naked Quad is a set of four unsolved cells in one row, column, or box whose combined candidates contain exactly four values.

Those four values must occupy the four cells, so they can be removed from every other cell in the unit.

## Example

```text
R1C1 {1,2}
R1C3 {2,3}
R1C5 {3,4}
R1C7 {1,4}
```

Together these cells contain only `{1,2,3,4}`. Candidates 1, 2, 3, and 4 may therefore be removed from every other cell in row 1.

## Implementation Contract

`Sudoku::Strategy::NakedQuads` discovers deductions only. It does not modify the grid directly.

The shared subset search lives in `Sudoku::Subset`.

## Test

```text
t/224_naked_quads.t
```
