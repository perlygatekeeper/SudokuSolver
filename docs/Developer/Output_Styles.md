# Output Styles

## Overview

SudokuSolver output should be understandable to a human reader.  The solver
should report its decision process in terms of passes, strategy attempts, and
individual deductions rather than legacy progress markers.

## Terms

### Pass

A pass begins with the easiest registered strategy and proceeds upward through
the strategy list until either a deduction is applied or every strategy fails.

When a deduction is applied, the next pass restarts at Naked Singles.

### Strategy Attempt

A strategy attempt is one check of a single strategy against the current grid.
It should report either:

```text
Naked Singles: no deductions.
Hidden Singles: applied 1 deduction.
```

### Deduction

A deduction is one logical action such as setting a value or removing a
candidate.  Human output should be based on `Sudoku::Deduction` objects.

Example:

```text
Hidden Single in Box 7:
    Set R9C2 = 6
    Reason: Candidate 6 appears only once in this box.
```

## Modes

```text
quiet
    Suppress solver narration and final status output.

normal
    Default mode. Print only the final solved/stalled/contradiction status.

explain
    Print each applied deduction in human-readable form, followed by final status.

trace
    Print pass boundaries, strategy attempts, applied deductions, restart notices,
    and final status.

debug
    Trace mode plus full candidate grids at diagnostic points.
```

## Rendering Boundary

Presentation belongs in renderer modules such as:

```text
lib/Sudoku/Render/Text.pm
```

`Solver` may choose when to render events, but the wording and layout of those
events should live in the renderer whenever practical.

## Mode Contract

`normal` output should be concise enough for routine command-line use. It should
not print every pass or every deduction.

`explain` output should show the deduction stream without the strategy-attempt
noise.

`trace` output should show the solver's control flow: pass start, each strategy
attempted, the deduction applied, and the restart from the easiest strategy.

`debug` output may be verbose and may include full candidate grids.

## Deduction Wording

Human-facing deductions should separate the action from its justification:

```text
Hidden Single in Box 7:
    Set R9C2 = 6
    Why: Candidate 6 appears only once in Box 7.
    Detail: R9C2 must be 6.
```

Structured unit context (`unit_type` and `unit_index`) should be carried by the
`Sudoku::Deduction` object rather than inferred from legacy text fragments.

For candidate removals, the renderer should preserve the strategy's logical
reason instead of repeating the removal action as the reason.
