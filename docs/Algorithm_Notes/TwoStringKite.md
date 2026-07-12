# Two-String Kite Algorithm Notes

## Pattern definition

For a candidate `d`, the implementation finds:

- a row containing exactly two unsolved cells with candidate `d`;
- a column containing exactly two unsolved cells with candidate `d`;
- one distinct endpoint from each strong link in the same box.

The joining endpoints must differ in both row and column. This ensures their
connection is specifically a box weak link rather than a degenerate row,
column, or shared-cell pattern.

The two non-joining endpoints are the remote endpoints. Any candidate-`d` cell
that sees both remote endpoints receives a `remove_candidate` deduction.

## Search procedure

For each candidate 1 through 9:

1. Build all row strong links.
2. Build all column strong links.
3. Compare every row link with every column link.
4. Try each of the four endpoint pairings as the possible box connection.
5. Reject shared-cell and non-box connections.
6. Find unsolved candidate cells that see both remote endpoints.
7. Deduplicate eliminations by row, column, and candidate.

## Correctness argument

Within each strong link, exactly one endpoint contains the candidate. If the
row connector is false, its remote row endpoint is true. If the row connector
is true, the column connector in the same box must be false, forcing the remote
column endpoint true. Thus at least one remote endpoint is true in every case.
A cell seeing both remote endpoints therefore cannot contain the candidate.

## Guard conditions

- Each string must contain exactly two candidates in its row or column.
- The joining cells must be distinct.
- The joining cells must share a box.
- The joining cells must not share a row or column.
- Pattern cells are never elimination targets.
- Duplicate eliminations from equivalent endpoint pairings are suppressed.
