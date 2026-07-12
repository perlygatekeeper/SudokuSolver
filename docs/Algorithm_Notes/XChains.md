# X-Chains Algorithm Notes

## Overview

For each candidate digit:

1. Build the strong-link graph with `Sudoku::StrongLinks`.
2. Build a weak-link visibility map between all unsolved cells containing the
   digit.
3. Start a depth-first search from each directed strong link.
4. Alternate weak and strong links without revisiting a candidate cell.
5. Whenever a path ends with a strong link and contains at least four nodes,
   inspect cells outside the path.
6. Remove the digit from any outside cell that sees both chain endpoints.

## Endpoint inference

For a chain

```text
A =S= B -W- C =S= D
```

if `A` is false, `B` is true, forcing `C` false and `D` true.  Conversely, if
`D` is false, the same reasoning in reverse forces `A` true.  Thus `A` and `D`
cannot both be false.

## Search limits

The implementation currently limits a path to nine links.  This keeps the
search bounded and predictable while covering compact human-solvable chains.
The fixed 9x9 board already provides a small search space, and duplicate
candidate eliminations are suppressed by cell and digit.

## Interaction with earlier strategies

Skyscraper, Two-String Kite, Empty Rectangle, and Simple Coloring run before
X-Chains.  They therefore claim their more recognizable deductions first.
X-Chains acts as the general same-digit alternating-chain strategy for patterns
that remain.

## Safety

A path never repeats a candidate cell.  It must begin and end with strong
links, alternate link types exactly, and contain at least three links.  The
elimination target must lie outside the path and see both endpoints.
