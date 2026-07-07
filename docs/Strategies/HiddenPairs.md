# Hidden Pairs

## Overview

**Legacy project name:** Hidden Pairs

Two candidates occur only in the same two cells.

## Recognition

Identify the pattern and verify all participating cells satisfy the requirements of the technique.

## Logical Basis

Remove all other candidates from those cells.

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
t/51_hidden_pairs.t
```

Tests should include:

- Positive detection
- Negative detection
- Correct eliminations or placements
- Idempotent execution

## References

- SudokuWiki
- Project developer documentation
