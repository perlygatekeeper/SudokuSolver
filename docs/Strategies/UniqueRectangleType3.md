# Unique Rectangle Type 3

Unique Rectangle Type 3 prevents a two-solution deadly rectangle by treating
the extra candidates in the two roof cells as one virtual cell in a naked
subset.

Four unsolved cells occupy two rows, two columns, and exactly two boxes. Two
floor cells contain only the same pair `{a,b}`. The two roof cells contain both
`a` and `b`, plus a combined set of extra candidates.

If those extras, treated as one virtual cell, combine with `n-1` other cells in
the shared roof row or column to form a naked subset of `n` candidates, those
extra candidates can be removed from every other cell in that unit.

This deduction assumes the puzzle has a unique solution. The explanation names
the rectangle, roof cells, extra set, supporting cells, target, and candidate.
