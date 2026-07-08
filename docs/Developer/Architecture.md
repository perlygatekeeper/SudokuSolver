# Architecture Rationale

SudokuSolver is being restored as a logic-first Sudoku solver. The primary
architectural goal is to separate representation, orchestration, solving
techniques, and command-line behavior.

## Why Separate the Pieces?

The legacy project works, but much of the behavior lives in large modules and
scripts. That makes it harder to test individual concepts and harder to extend
the solver safely.

The project should move toward this shape:

```text
bin/sudoku.pl
    command-line interface only

Solver.pm
    puzzle loading and solve orchestration

Grid.pm
    board representation and candidate state

Strategy::*
    individual solving techniques
```

The command-line script should not know how solving works. It should parse user
input, create a solver, run it, and print results.

The solver should not directly encode every solving technique forever.
Initially it may call existing `Grid` methods, but over time it should delegate
to strategy modules.

The grid should represent the puzzle and expose safe operations for reading
cells, setting values, and eliminating candidates. It should gradually stop
owning high-level strategy logic.

## Why Preserve Behavior First?

The project already contains useful solving logic. Early cleanup should
preserve existing behavior while improving structure. A behavior-preserving
refactor is safer than adding features while moving code.

For v0.5.x, prefer small patches that:

* keep `make check` passing,
* do not introduce new solving techniques,
* preserve existing output unless the patch explicitly changes output,
* make later tests and refactors easier.



## Deduction Objects

Strategy modules should eventually return `Sudoku::Deduction` objects rather
than printing directly or merely returning a boolean progress flag.

A Deduction object describes one logical action:

* the strategy that found the deduction,
* the action being proposed or performed,
* the affected cell or cells,
* the affected value or candidate,
* the reason the deduction is valid,
* and an optional human-readable explanation.

This creates a common data stream for future features:

```text
Strategy
    -> Deduction
    -> Solver
    -> Explanation Log
    -> Hint / Report / Statistics / Difficulty Rating
```

The first implementation of `Sudoku::Deduction` is intentionally small.  The
legacy strategies may continue returning progress counts while they are being
migrated.  Once the object contract is stable, each strategy can begin returning
Deduction objects without changing the command-line interface.


## Hint Mode

`Solver->hint($grid)` returns the next available `Sudoku::Deduction` without
applying it to the grid and without recording it in the solver deduction log.

This gives user interfaces a safe way to ask, "What is the next logical move?"
without changing puzzle state.

Relationship between related APIs:

```perl
my $deduction = $solver->hint($grid); # inspect next move, no mutation
my $deduction = $solver->step($grid); # apply and record one move
$solver->run(...);                   # solve until solved, stalled, or contradicted
```

Hint Mode follows the same tiered strategy order as the solver. It returns the
first deduction found by the easiest currently applicable strategy.


## Long-Term Direction

Eventually each solving strategy should be explainable. A strategy should not
merely change the grid; it should also be able to report what it changed and
why the deduction is valid.

That design supports future features such as hint mode, explain mode, strategy
statistics, and difficulty estimation.

## Solver Deduction Log

`Solver` owns the deduction log. Strategies may produce `Sudoku::Deduction`
objects, and the solver records them in order. This keeps the solving
process separate from presentation while preparing for Hint Mode, Explain
Mode, statistics, and difficulty analysis.

Current Solver log methods:

```perl
$solver->record_deduction($deduction);
$solver->deductions;
$solver->deduction_count;
$solver->clear_deductions;
```

The log is intentionally simple at this stage. Future work will make the
solver responsible for applying deductions consistently across all strategy
modules.


## Strategy Registry

`Sudoku::Strategy` owns the canonical ordered strategy list.

The registry provides:

```perl
Sudoku::Strategy->ordered_strategy_classes;
Sudoku::Strategy->ordered_strategy_names;
Sudoku::Strategy->strategies;
```

`Solver` uses this list as the default strategy order.  This keeps strategy
ordering in one place and prepares the solver for configurable strategy sets,
strategy statistics, difficulty scoring, and Hint Mode.

## Tiered Strategy Restart Order

The solver preserves the legacy strategy hierarchy. Strategies are ordered from
easiest to hardest. A solving pass starts with the easiest strategy and climbs
only when easier strategies fail.

When any strategy makes progress, the solver stops the current pass and starts
the next pass again from the easiest strategy. This means a successful Hidden
Pair, X-Wing, or other higher-tier strategy immediately gives Naked Singles and
other easier strategies the next opportunity to act.

This behavior is intentional because higher-tier deductions often expose simpler
follow-up deductions. It also keeps the solve log aligned with a human-style
solving hierarchy and provides a natural basis for future difficulty scoring.


## Strategy Contract Audit

Phase 1 formalizes the strategy contract.

A strategy module is responsible for discovering logical deductions only.  It
must not apply those deductions directly and it must not produce user-facing
output.

Current strategy contract:

```perl
my @deductions = $strategy->apply($grid);
```

Strategy modules must:

* inspect the `Grid`, `Cell`, and candidate state,
* return zero or more `Sudoku::Deduction` objects,
* leave all puzzle mutation to `Solver` or legacy Grid wrapper code,
* avoid printing directly,
* avoid setting cell values directly,
* avoid removing candidates directly,
* avoid replacing candidate arrays directly.

This keeps the responsibilities separated:

```text
Strategy
    finds deductions

Deduction
    describes logical actions

Solver
    applies deductions and records the solve log

Grid / Cell
    represent puzzle state
```

The contract is enforced by `t/39_strategy_contract.t`.

## Step-by-Step Solving

`Solver->step($grid)` performs one logical deduction. It scans the registered
strategies in canonical order, applies the first deduction that makes progress,
records it in the solver deduction log, and returns the applied `Sudoku::Deduction`
object.

If no strategy can make progress, `step` returns undef.

This API is the foundation for Hint Mode, Explain Mode, and interactive
step-by-step solving. Full `run()` behavior should remain compatible with the
legacy tiered strategy order, while `step()` exposes one deduction at a time.
