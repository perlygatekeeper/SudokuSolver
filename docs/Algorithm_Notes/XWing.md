# X-Wing

## Purpose

X-Wing is a candidate-elimination strategy. It does not directly place a value.
Instead, it proves that a candidate must occupy one of two matching positions
in two different rows or columns, allowing that candidate to be removed from
other cells in the intersecting columns or rows.

## Human intuition

Suppose candidate `7` appears in exactly two cells in Row 2:

- R2C3
- R2C8

Now suppose candidate `7` also appears in exactly two cells in Row 6:

- R6C3
- R6C8

Those four cells form the corners of a rectangle:

        C3      C8

R2      7       7

R6      7       7

Row 2 must place its `7` in either C3 or C8. Row 6 must also place its `7` in
either C3 or C8. They cannot both place `7` in the same column, so they must
use opposite corners. Therefore Columns 3 and 8 each receive one of those two
`7`s, and no other cell in either column may contain candidate `7`.

## Row-based X-Wing

A row-based X-Wing exists for candidate `v` when:

1. Candidate `v` appears in exactly two cells in Row A.
2. Candidate `v` appears in exactly two cells in Row B.
3. Those candidate positions occur in the same two columns.

Then remove candidate `v` from every other unsolved cell in those two columns.
The four X-Wing corner cells are excluded from elimination.

## Column-based X-Wing

The same pattern may be rotated.

A column-based X-Wing exists for candidate `v` when:

1. Candidate `v` appears in exactly two cells in Column A.
2. Candidate `v` appears in exactly two cells in Column B.
3. Those candidate positions occur in the same two rows.

Then remove candidate `v` from every other unsolved cell in those two rows.

## Why the name “X-Wing”?

If the four corner cells are connected diagonally, the two possible placements
form an `X`. The candidate must occupy one diagonal pair or the other.

## Necessary conditions

For a standard X-Wing:

- One candidate value is considered at a time.
- Two base units are selected: two rows or two columns.
- Each base unit has exactly two candidate positions for that value.
- The two candidate-position sets are identical.
- At least one elimination exists outside the four corner cells.

A strategy should return no deduction if the pattern produces no elimination.

## What X-Wing does not require

The four corner cells do not need to be bivalue cells. A corner could contain
`{2,5,7}` as long as candidate `7` occurs in the required X-Wing position.
X-Wing is about the distribution of one candidate across rows and columns, not
the complete candidate sets of the corners.

## Common human recognition method

Choose one candidate value and scan the grid.

For each row:

1. Find rows where the candidate appears exactly twice.
2. Note the two columns.
3. Look for another row with the same two columns.

Then repeat with columns as the base units.

A shorthand might be:

7:
    R2 -> C3, C8
    R6 -> C3, C8

## Proof of correctness

Assume candidate `v` appears only in Columns C1 and C2 within both Rows R1 and R2.

Each row must contain `v` exactly once. They cannot both select C1, and they
cannot both select C2, because a column cannot contain duplicate values. Thus
one row selects C1 and the other selects C2. Therefore both columns are
guaranteed to receive `v` from one of the two base rows, so any other
occurrence of `v` in those columns is impossible.

## Algorithm

### Row-based search

For each candidate value `1 .. 9`:

1. For each row, collect the columns where the candidate remains possible.
2. Keep rows having exactly two such columns.
3. Compare each pair of those rows.
4. If their two-column sets are identical, treat the rows as base units and the columns as cover units.
5. Remove the candidate from other cells in the two cover columns.

### Column-based search

Repeat with rows and columns exchanged.

## Pseudocode

for candidate in 1 through 9:

    row_positions = rows having exactly two positions for candidate

    for each pair of rows:
        if their column-position sets are identical:

            for each matching column:
                for each other row:
                    remove candidate from that cell

Then repeat in the opposite orientation.

## Deduction information

An X-Wing deduction should record enough information for a human to verify it:

- strategy
- candidate value
- orientation
- base rows or columns
- cover columns or rows
- four corner cells
- target cell

Example:

X-Wing on candidate 7:

    Base rows: R2 and R6
    Cover columns: C3 and C8
    Corners: R2C3, R2C8, R6C3, R6C8

Remove candidate 7 from R4C3.

Why: In Rows 2 and 6, candidate 7 can appear only in Columns 3
and 8. Those two rows must place their 7s in opposite corners,
so Column 3 already receives a 7 from one of the X-Wing rows.

## Implementation pitfalls

### Accepting more than two positions

A standard X-Wing requires exactly two candidate positions in each base unit. A
row with positions `C2, C5, C8` does not form a standard X-Wing.

### Mismatched cover units

These do not form an X-Wing:

R2 -> C3, C8
R6 -> C3, C9

The position sets must be identical.

### Eliminating from the base cells

Never remove the candidate from the four X-Wing corners. Only remove it from
other cells in the cover units.

### Returning deductions when nothing changes

The pattern may exist geometrically but produce no eliminations. In that case
the strategy should return no deductions.

### Mixing candidates

All four corners and all eliminations must concern the same candidate value.

### Duplicate deductions

Repeated comparisons may rediscover the same elimination. Deduplicate by target
cell and candidate.

## Relationship to other fish strategies

X-Wing is a size-2 fish:

X-Wing     = 2 base units and 2 cover units
Swordfish  = 3 base units and 3 cover units
Jellyfish  = 4 base units and 4 cover units

The general principle is:

> If candidate `v` is confined to N cover units across N base units, then
> candidate `v` may be removed from all other cells in those cover units.

This suggests a reusable fish engine:

fish size 2 -> X-Wing
fish size 3 -> Swordfish
fish size 4 -> Jellyfish

## Tests the strategy should have

### Positive row-based test

- Two rows each contain the candidate in the same two columns.
- Another cell in one cover column contains the candidate.
- The strategy removes it.

### Positive column-based test

- Two columns each contain the candidate in the same two rows.
- Another cell in one cover row contains the candidate.
- The strategy removes it.

### Negative tests

- One base unit has three candidate positions.
- The position sets differ.
- The target does not contain the candidate.
- No elimination exists.
- The four corner cells are not modified.
- No duplicate deductions are returned.

## Learning summary

When looking for an X-Wing, ask:

1. Which candidate am I tracking?
2. Does it appear exactly twice in one row?
3. Does another row have exactly the same two candidate columns?
4. If so, can I remove that candidate elsewhere in those columns?

Or rotate the question for columns.

The heart of X-Wing is not the rectangle itself. It is the guarantee that two
base units must distribute the candidate across the same two cover units.
