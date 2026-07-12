# X-Chains

## Purpose

An X-Chain follows one candidate digit through an alternating sequence of
strong and weak links.

A strong link means exactly one of its two endpoints must contain the digit.  A
weak link means the two endpoints cannot both contain the digit.  When a chain
begins and ends with strong links, its two endpoints cannot both be false.
Therefore, any outside candidate that sees both endpoints can be removed.

## Pattern

A minimal X-Chain has this form:

```text
A =strong= B -weak- C =strong= D
```

At least one of `A` or `D` must be true.  A candidate cell that sees both `A`
and `D` cannot contain the digit.

Longer chains continue alternating weak and strong links:

```text
A =S= B -W- C =S= D -W- E =S= F
```

## Solver behavior

The strategy searches one digit at a time.  Strong links come from conjugate
pairs in rows, columns, and boxes through `Sudoku::StrongLinks`.  Weak links
connect any two candidate cells for the digit that see each other.

The strategy emits structured candidate-removal deductions.  Each deduction
records the chain cells and displays the chain with `=S=` and `-W-` markers in
its human-readable reason.
