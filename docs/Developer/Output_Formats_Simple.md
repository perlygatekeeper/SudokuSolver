# Output Formats

## Existing

### Grid

- Pretty Grid
- Candidate Grid
- Puzzle String
- Numeric Grid

### Narration

- quiet
- normal
- explain
- trace
- debug

### Reports

- Final Status
- Benchmark Summary

## Planned

### Grid

- Compact grid
- Pretty grid (string-returning)
- Unicode variant

### Candidate State

- Human-readable dump
- Single-line 81-field export
- JSON export

### Machine Formats

- JSON
- CSV
- TSV

### Miscellaneous

- One-line puzzle
- One-line solution
- Output-to-file
- Stable event rendering
- Optional color layer

## Guiding Principle

Views, formats, narration, and destinations should remain orthogonal so users
can mix and match them naturally.
