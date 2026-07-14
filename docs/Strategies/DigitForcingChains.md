# Digit Forcing Chains

Digit Forcing Chains test both possible states of one candidate:

- the candidate is true; and
- the candidate is false.

Each branch receives one temporary assumption and then uses only deterministic
solver strategies. No branch may introduce another assumption.

A deduction is valid when:

1. one branch reaches a contradiction, proving the opposite state;
2. both branches place the same value in a cell; or
3. both branches eliminate the same candidate.

The strategy stops after the first proof and returns one structured deduction.
This keeps normal solver behavior intact: apply one deduction, restart from
Naked Singles, and prefer simpler strategies whenever they are available.

## Boundary with search

Digit Forcing Chains are deliberately bounded hypothetical reasoning, not a
recursive backtracking solver. The implementation has one branch point, a hard
propagation limit, no nested assumptions, and an explanation that exposes the
proof found in both branches.

## Search boundary

The enhanced implementation considers every remaining candidate in a nonempty puzzle, including candidates in cells with three or more possibilities. Premises are ordered heuristically: candidates in smaller cells and candidates participating in row, column, or box conjugate pairs are tried first.

The ON branch runs first. If it contradicts, the candidate is removed immediately without running the OFF branch. Otherwise the OFF branch is evaluated for an opposite contradiction or a conclusion shared by both branches.

Hypothetical propagation uses only Naked Singles and Hidden Singles, does not invoke another forcing strategy, and is limited to 50 propagated deductions per branch.

