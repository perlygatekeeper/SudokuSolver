# Skyscraper Algorithm Notes

## Human pattern

For one candidate, find two rows in which the candidate appears exactly twice.
The two pairs must share exactly one column.

The cells in the shared column are the floors. The two unmatched cells are the
roofs. At least one roof must be true:

- If the first floor is false, its roof is true.
- If the first floor is true, the second floor is false because the floors
  share a column, so the second roof is true.

A candidate in any cell that sees both roofs can therefore be eliminated.
The same reasoning works with rows and columns transposed.

## Discovery algorithm

For each candidate 1 through 9:

1. Find every row containing exactly two instances of that candidate.
2. Compare each pair of row strong links.
3. Require their candidate-column sets to intersect in exactly one column.
4. Treat the shared-column cells as floors and the unmatched cells as roofs.
5. Find unsolved candidate cells that see both roofs.
6. Return one `remove_candidate` deduction for each unique target.
7. Repeat with columns as the base units.

## Safety conditions

- Each base unit must contain exactly two candidates, establishing a strong
  link.
- The two links must share exactly one cover unit.
- Sharing zero cover units is disconnected.
- Sharing two cover units is an X-Wing, not a Skyscraper.
- Pattern cells are never elimination targets.
- The strategy only discovers deductions; Solver applies them.

## Explanation data

Each deduction records all four pattern cells in this order:

1. first floor,
2. first roof,
3. second floor,
4. second roof.

The reason names the orientation, both strong links, the shared floor unit, both
roofs, and the target cell.
