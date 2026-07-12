# Two-String Kite

A Two-String Kite is a single-candidate chain made from one row strong link and
one column strong link. One endpoint of each strong link lies in the same box.
Those two box cells join the row and column "strings."

The endpoints outside the joining box are the remote endpoints. At least one of
those remote endpoints must contain the candidate. Therefore, any unsolved cell
that sees both remote endpoints cannot contain that candidate.

## Human-solving procedure

For one candidate:

1. Find a row in which the candidate appears exactly twice.
2. Find a column in which the candidate appears exactly twice.
3. Check whether one endpoint from the row and one endpoint from the column lie
   in the same box.
4. Identify the other endpoint of each strong link.
5. Eliminate the candidate from cells that see both remote endpoints.

## Example

Suppose candidate 5 occurs exactly twice in row 1, at R1C1 and R1C5, and
exactly twice in column 2, at R2C2 and R6C2. R1C1 and R2C2 share box 1, so they
join the two strings. The remote endpoints are R1C5 and R6C2.

R6C5 sees R1C5 through column 5 and R6C2 through row 6. Since at least one
remote endpoint must be 5, R6C5 cannot be 5.

## Solver behavior

`Sudoku::Strategy::TwoStringKite` is discovery-only. It returns structured
`Sudoku::Deduction` objects and does not mutate the grid directly. Each
explanation names both strong links, the joining box cells, both remote
endpoints, and the eliminated candidate.
