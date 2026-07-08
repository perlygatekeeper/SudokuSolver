# Difficulty Rating v1.0

## Overview

Difficulty ratings are versioned interpretations of solver statistics. A rating
is not a permanent fact about a puzzle; it is the result of applying a specific
rating method to a specific solve log.

Every difficulty result records:

- rating method version
- label
- numeric score
- highest strategy used
- statistics snapshot used to derive the rating

This allows future versions of SudokuSolver to re-evaluate a puzzle when the
rating algorithm changes.

## Version

```text
1.0
```

## Method

Version 1.0 rates a puzzle by the hardest strategy present in the deduction log.

| Highest Strategy | Score | Label |
|------------------|------:|-------|
| none | 0 | Unrated |
| Naked Singles | 1 | Trivial |
| Hidden Singles | 2 | Easy |
| Pointing / Claiming | 3 | Medium |
| Naked Pairs | 4 | Hard |
| Hidden Pairs | 4 | Hard |
| X-Wing | 5 | Expert |
| Remote Pairs | 6 | Master |

## Rationale

This first version is intentionally simple and deterministic. It avoids
pretending that difficulty is absolute, while still producing a useful rating
from the current engine.

Later versions may incorporate:

- total deduction count
- weighted strategy counts
- number of solving passes
- candidate removals
- contradiction/stalled status
- benchmark performance

## Re-evaluation

Because each rating stores both the rating method version and the statistics
snapshot, future methods can re-rate an old solve without re-running the solver.
