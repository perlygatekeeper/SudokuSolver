# Digit Forcing Chains Algorithm Notes

## Candidate selection

Build a premise for every remaining candidate in every unsolved cell with at
least two candidates. Premises are scored before searching. Smaller cells rank
higher, and a candidate receives an additional score when it has two or three
remaining locations in its row, column, or box. Ties are resolved in stable
row, column, and candidate order.

A completely empty grid is skipped because it has no constrained premise and
is used by the benchmark test suite as a deliberately stalled puzzle.

## Branches

For each premise `RrCc(d)`, run the ON branch first by temporarily setting
`RrCc=d`. If that branch contradicts, remove `d` immediately and do not run
the OFF branch. Otherwise run the OFF branch by temporarily removing `d` from
`RrCc`, then compare the two completed branches.

`Sudoku::Hypothetical` clones the exact candidate state and calls bounded
`Solver::propagate()`. Its default strategy filter excludes forcing and
hypothetical strategies, preventing nested assumptions.

## Comparison

The comparison order is:

1. ON contradiction -> remove the premise candidate;
2. OFF contradiction -> place the premise candidate;
3. same placement in both branches -> place that value;
4. same false candidate in both branches -> remove that candidate.

A candidate is false in a branch when its cell is solved to another value or
when it remains unsolved and the candidate is absent. A cell solved to the
candidate is therefore never mistaken for an elimination.

If both branches contradict, no deduction is emitted because the incoming grid
state is itself inconsistent.

## Propagation boundary

Branches propagate only Naked Singles and Hidden Singles. This matches the
contradiction chains observed in the four frontier benchmark puzzles while
keeping the proof short, deterministic, and human-readable. Advanced chains
and forcing strategies are never invoked inside a branch.

## Limits

The default branch limit is 50 propagated deductions. Reaching a limit does
not count as a contradiction or a completed proof.
