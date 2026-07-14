# Naked Triples

## Overview

A Naked Triple is a set of three unsolved cells in one row, column, or box whose combined candidates contain exactly three values.

The three values must occupy those three cells, so they can be removed from every other cell in the unit.

## Example

```text
R1C1 {1,2}
R1C4 {1,3}
R1C7 {2,3}
```

Together these cells contain only `{1,2,3}`. Candidates 1, 2, and 3 may therefore be removed from every other cell in row 1.

## Implementation Contract

`Sudoku::Strategy::NakedTriples` discovers deductions only. It does not modify the grid directly.

The shared subset search lives in `Sudoku::Subset`.

## Test

```text
t/222_naked_triples.t
```
