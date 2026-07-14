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

## Initial search boundary

This first implementation tests candidates only in bivalue cells and propagates Naked Singles, Hidden Singles, Pointing / Claiming, Naked Pairs, and Hidden Pairs. It does not recursively invoke advanced chain or forcing strategies. Each branch is limited to 100 propagated deductions.

