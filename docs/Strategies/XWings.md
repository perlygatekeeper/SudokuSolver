# X-Wing

## Overview

**Legacy project name:** X-Wing

A candidate forms a rectangle across two rows and two columns.

## Recognition

Identify the pattern and verify all participating cells satisfy the requirements of the technique.

## Logical Basis

Remove that candidate from other cells in the affected columns/rows.

## Example

```
(Add a worked example from the regression test suite.)
```

## Solver Responsibilities

1. Detect the pattern.
2. Verify the pattern.
3. Produce deductions.
4. Return an explanation suitable for Hint Mode.

## Testing

Primary test file:

```
t/60_x_wings.t
```

Tests should include:

- Positive detection
- Negative detection
- Correct eliminations or placements
- Idempotent execution

## References

- SudokuWiki
- Project developer documentation
