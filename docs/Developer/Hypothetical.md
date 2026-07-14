# Hypothetical Inference Engine

`Sudoku::Hypothetical` evaluates one temporary candidate assumption on a clone
of the current grid. It is infrastructure for forcing-chain strategies; it is
not itself a registered solving strategy.

## Boundary from search

A hypothetical run has exactly one externally supplied assumption. After that
assumption, the normal deterministic strategy pipeline propagates deductions.
The engine never chooses another candidate, never recursively branches, and
never accepts a completed hypothetical solve as a deduction by itself.

Each run stops at one of four states:

- `contradiction`
- `fixed_point`
- `solved`
- `limit`

The hard step limit prevents an accidental unbounded propagation run.

## API

```perl
my $result = Sudoku::Hypothetical->new(
    grid       => $grid,
    row        => 3,
    column     => 6,
    value      => 7,
    assumption => 'on',       # or 'off'
    max_steps  => 500,
)->run;
```

The original grid is never modified. The result contains an independent cloned
grid, propagated deductions, placements, eliminations, history, status, and an
optional structured contradiction.

A caller may provide `strategy_classes` to restrict propagation. By default the
engine uses the ordered deterministic strategy list while excluding strategy
class names associated with forcing, Nishio, or hypothetical search. This guard
prevents future forcing strategies from recursively invoking themselves.

## History

The first history entry describes the assumption. Later entries contain the
strategy and structured deduction for each propagated step. The assumption is
not included in `placements` or `eliminations`; those collections contain only
logical consequences of the branch.

## Solver propagation

`Solver::propagate()` exposes the bounded deterministic loop used by the
hypothetical engine. It applies one deduction at a time with the normal restart
policy and returns a status, step count, and history.
