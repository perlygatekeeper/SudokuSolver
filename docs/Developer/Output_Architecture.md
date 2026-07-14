# Output Architecture

## Goals

- Separate solving from presentation.
- Make output formats composable.
- Support human and machine-readable output.
- Preserve merge safety with the strategy branch.

## Layers

Solver
↓
Deduction Objects
↓
(Future) Event Objects
↓
Renderers
    - Text
    - JSON
    - CSV/TSV
    - Candidate Export
↓
Destination
    - Terminal
    - File
    - Tests
    - API

## Primary Concepts

### Grid Views

- Compact
- Pretty
- Candidate

### Narration Modes

- quiet
- normal
- explain
- trace
- debug

These are independent concepts.

## Future

Structured events should eventually become the common source consumed by all
renderers.
