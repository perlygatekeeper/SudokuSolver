# XY-Chains Algorithm Notes

## Representation

Each node is an unsolved cell with exactly two candidates. A search state
contains:

- the ordered path of bivalue cells;
- the candidate entering the current cell;
- the candidate that must leave the current cell;
- the endpoint candidate shared by the first and desired last cells;
- a visited-cell set.

For a cell `{x,y}` entered through `x`, the chain must leave through `y`.
The next cell must see the current cell and contain `y`.

## Completion condition

A path completes when the other candidate in the newly reached cell equals
the starting endpoint candidate. With endpoints `A` and `B` sharing `z`, the
alternating implications prove that at least one of `A(z)` and `B(z)` is true.
Every candidate `z` outside the path that sees both endpoints can be removed.

## Safety constraints

- Every chain cell is bivalue.
- Consecutive cells must see each other.
- The required outgoing candidate must occur in the next cell.
- Cells cannot repeat within a path.
- Only cells seeing both endpoints are elimination targets.
- Deductions are deduplicated by target cell and candidate.
- Search depth is bounded to nine cells.

## Relationship to XY-Wing

An XY-Wing is the shortest useful XY-Chain. The specialized XY-Wing strategy
runs earlier and normally claims those deductions with its more familiar human
explanation. XY-Chains handles the longer general case.
