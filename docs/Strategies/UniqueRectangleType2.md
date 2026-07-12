# Unique Rectangle Type 2

## Overview

A Type 2 Unique Rectangle has two floor cells containing only `{A,B}` and two aligned roof cells containing exactly `{A,B,C}`. At least one roof must contain `C` to prevent the deadly rectangle, so candidate `C` can be removed from every other cell that sees both roof cells.

## Uniqueness Assumption

This strategy depends on the puzzle having exactly one solution.

## Solver Contract

The strategy inspects the grid without modifying it and returns `Sudoku::Deduction` objects for candidate eliminations.

## Safety Conditions

The implementation deliberately recognizes only the conservative form where:

- the rectangle occupies exactly two rows, two columns, and two boxes;
- the two floor cells are aligned and contain exactly `{A,B}`;
- the two roof cells are aligned and contain exactly `{A,B,C}`;
- both roof cells share the same single extra candidate `C`;
- each elimination target sees both roof cells.
