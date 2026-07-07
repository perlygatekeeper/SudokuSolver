# Naked Singles

## Overview

**Legacy project name:** Singletons

A cell has exactly one remaining candidate.

## Recognition

Identify the pattern and verify all participating cells satisfy the requirements of the technique.

## Logical Basis

Place the remaining value in the cell.

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
t/40_singletons.t
```

Tests should include:

- Positive detection
- Negative detection
- Correct eliminations or placements
- Idempotent execution

## References

- SudokuWiki
- Project developer documentation
