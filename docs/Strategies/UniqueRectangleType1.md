# Unique Rectangle Type 1

## Overview

A Unique Rectangle occupies exactly two rows, two columns, and two boxes. In Type 1, three corners contain only the same candidate pair `{A,B}`, while the fourth corner contains `{A,B}` plus one or more extra candidates.

To preserve the puzzle's assumed unique solution, candidates `A` and `B` are removed from the fourth corner.

## Uniqueness Assumption

This strategy depends on the puzzle having exactly one solution. It is therefore categorized separately from deductions derived solely from row, column, and box constraints.

## Solver Contract

The strategy inspects the grid without modifying it and returns one `Sudoku::Deduction` for each deadly-pair candidate removed from the roof cell.

## Safety Conditions

The implementation requires:

- four unsolved cells in exactly two rows and two columns;
- the four cells to occupy exactly two boxes;
- three cells to contain exactly the same two candidates;
- the fourth cell to contain both pair candidates and at least one extra candidate.
