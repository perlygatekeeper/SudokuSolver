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
    Suppress normal solver narration.

normal
    Default human-readable pass and deduction output.

explain
    Emphasize deduction explanations.

trace
    Intended for detailed strategy/deduction tracing.

debug
    Include full candidate grids at diagnostic points.
```

## Rendering Boundary

Presentation belongs in renderer modules such as:

```text
lib/Sudoku/Render/Text.pm
```

`Solver` may choose when to render events, but the wording and layout of those
events should live in the renderer whenever practical.
