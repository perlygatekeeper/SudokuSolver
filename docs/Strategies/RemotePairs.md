# Remote Pairs

## Overview

**Legacy project name:** Remote Pairs

A chain of bivalue cells shares the same candidate pair.

## Recognition

Identify the pattern and verify all participating cells satisfy the requirements of the technique.

## Logical Basis

Eliminate candidates seen by both ends of the chain.

## Example

(Add a worked example from the regression test suite.)

## Solver Responsibilities

1. Detect the pattern.
2. Verify the pattern.
3. Produce deductions.
4. Return an explanation suitable for Hint Mode.

## Testing

Primary test file:

t/400_remote_pairs.t

Tests should include:

- Positive detection
- Negative detection
- Correct eliminations or placements
- Idempotent execution

## References

- SudokuWiki
- Project developer documentation
