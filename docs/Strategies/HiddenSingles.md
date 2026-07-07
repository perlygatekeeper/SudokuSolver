# Hidden Singles

## Overview

**Legacy project name:** Lone Representatives

A candidate appears in only one cell within a row, column, or box.

## Recognition

Identify the pattern and verify all participating cells satisfy the requirements of the technique.

## Logical Basis

Place that candidate in the unique cell.

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
t/41_lone_representatives.t
```

Tests should include:

- Positive detection
- Negative detection
- Correct eliminations or placements
- Idempotent execution

## References

- SudokuWiki
- Project developer documentation
