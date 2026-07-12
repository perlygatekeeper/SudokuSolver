# XY-Chains

## Summary

An XY-Chain is a sequence of unsolved bivalue cells. Consecutive cells see one
another and share one candidate. The shared candidate changes at every step.
The first and last cells contain the same endpoint candidate.

At least one endpoint must contain that candidate. Any other cell that sees
both endpoints can therefore have the endpoint candidate removed.

## Example

```text
R1C1 {1,9} - R1C4 {1,2} - R4C4 {2,3} - R4C7 {3,9}
```

If R1C1 is not 9, it must be 1. That forces R1C4 to 2, R4C4 to 3, and R4C7
to 9. Thus either R1C1 or R4C7 is 9. A cell that sees both cannot be 9.

## Solver behavior

The solver:

1. Collects all bivalue cells.
2. Starts from each candidate of each possible endpoint.
3. Follows visible bivalue cells through the other candidate.
4. Stops when the chain reaches a cell containing the starting endpoint
   candidate.
5. Removes that candidate from common peers of the endpoints.

The search is bounded to nine cells and does not revisit a cell.
