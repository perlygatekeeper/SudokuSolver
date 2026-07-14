# Digit Forcing Chains Algorithm Notes

## Candidate selection

Visit unsolved cells in grid order and their remaining candidates in numeric
order. Candidates in solved or single-candidate cells are not used as branch
premises.

## Branches

For each premise `RrCc(d)` run:

- ON: temporarily set `RrCc=d`;
- OFF: temporarily remove `d` from `RrCc`.

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

## Initial search boundary

This first implementation tests candidates only in bivalue cells and propagates Naked Singles, Hidden Singles, Pointing / Claiming, Naked Pairs, and Hidden Pairs. It does not recursively invoke advanced chain or forcing strategies. Each branch is limited to 100 propagated deductions.

## Limits

The default branch limit is 500 propagated deductions. Reaching a limit does
not invalidate deductions already derived in that branch, but the strategy
never treats a limit as a contradiction or a completed solve.
