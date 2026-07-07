# Sudoku Solving Strategies

## Overview

SudokuSolver is intended to be a logic-based solver. Its primary goal is not merely to fill a grid, but to explain why each deduction is valid.

This document describes the strategy families currently represented in the project and the intended direction for organizing them.

---

## Strategy Philosophy

Each solving strategy should eventually be responsible for four things:

1. Determine whether the strategy applies.
2. Identify the affected cell or candidate.
3. Apply the deduction.
4. Explain why the deduction is valid.

A future strategy result might contain:

Strategy: Hidden Single
Action: Set R3C7 = 5
Reason: In row 3, candidate 5 can appear only in column 7.

This structure supports both solving and hint generation.

---

## Basic Strategies

### Naked Singles

Historical project name:

Singletons

A cell has only one remaining possible value.

Example:

R4C5 candidates: {7}
Therefore R4C5 = 7.

---

### Hidden Singles

Historical project name:

Lone Representatives

A value appears as a candidate in only one cell within a row, column, or box.

Example:

In row 6, candidate 9 appears only in C2.
Therefore R6C2 = 9.

---

### Pointing and Claiming

Historical project name:

Imaginary Values

A candidate is restricted to a single row or column within a box, allowing that candidate to be removed elsewhere in the same row or column.

Example:

In box 4, all candidate 3s are in row 5.
Therefore 3 may be removed from row 5 outside box 4.

---

## Intermediate Strategies

### Naked Pairs

Two cells in the same unit contain exactly the same two candidates. Those two values can be removed from other cells in that unit.

Example:

R2C3 candidates: {4, 8}
R2C7 candidates: {4, 8}

Therefore 4 and 8 may be removed from other cells in row 2.

---

### Hidden Pairs

Two values appear only in the same two cells within a unit. Other candidates may be removed from those two cells.

Example:

In column 5, candidates 2 and 6 appear only in R1C5 and R7C5.

Therefore R1C5 and R7C5 may contain only {2, 6}.

---

## Advanced Strategies

### X-Wing

A candidate appears in exactly two positions in each of two rows, and those positions share the same columns. The candidate can be removed from other cells in those columns.

The same pattern may also be viewed column-first.

Example:

Candidate 7 appears only in C2 and C8 of rows 3 and 6.

Therefore 7 may be removed from all other cells in columns 2 and 8.

---

### Remote Pairs

Remote Pairs use chains of bivalue cells containing the same pair of candidates. If two cells connected by the chain see a common cell, candidates may be eliminated from that common cell.

This strategy is currently experimental in the legacy codebase and should be reviewed carefully before being treated as stable.

---

## Strategy Module Direction

Eventually, each strategy should live in its own module:

lib/Sudoku/Strategy/Singletons.pm
lib/Sudoku/Strategy/HiddenSingles.pm
lib/Sudoku/Strategy/PointingClaiming.pm
lib/Sudoku/Strategy/NakedPairs.pm
lib/Sudoku/Strategy/HiddenPairs.pm
lib/Sudoku/Strategy/XWing.pm
lib/Sudoku/Strategy/RemotePairs.pm

Each module should expose a consistent interface.

Possible future contract:

my @deductions = $strategy->apply($grid);

Each deduction should describe:

- affected cell
- affected candidate or value
- action taken
- explanation
- strategy name

---

## Naming Convention

The original project terms should be preserved in historical notes, but public code and user-facing documentation should prefer standard Sudoku names.

| Legacy Name | Standard Name |
|------------|---------------|
| Singleton | Naked Single |
| Lone Representative | Hidden Single |
| Imaginary Value | Pointing / Claiming |
| Naked Pair | Naked Pair |
| Hidden Pair | Hidden Pair |
| X-Wing | X-Wing |
| Remote Pair | Remote Pair |

---

## Testing Strategy

Strategy tests should verify behavior, not internal implementation.

Recommended numbering:

40_singletons.t
41_lone_representatives.t
42_imaginary_values.t

50_naked_pairs.t
51_hidden_pairs.t

60_x_wings.t
61_remote_pairs.t

Each test should:

1. Construct a controlled grid.
2. Arrange candidates so the strategy applies.
3. Run the strategy.
4. Verify the expected value placement or candidate removal.
5. Avoid depending on unrelated solver behavior.

---

## Long-Term Goal

The long-term goal is an explainable solver.

SudokuSolver should eventually be able to answer:

What is the next logical move?
Why is that move valid?
Which strategy found it?
What candidates were removed?
What value was placed?

This goal should guide the architecture even before the full explanation system is implemented.
