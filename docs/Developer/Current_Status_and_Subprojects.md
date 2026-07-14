# Current Status and Sub-Project Plans

## Current Branch

`feature/enhanced-output-methods`

The branch remains intentionally orthogonal to active strategy and benchmarking
work. Existing output remains backward-compatible because many tests use exact
output text as part of their success criteria.

## Enhanced Output Status

Completed patches:

1. Grid character sets
2. Reusable grid builder
3. String-returning pretty grid
4. Compact grid renderer
5. Grid format registry
6. Candidate grid renderer
7. CLI format discovery and selection
8. Human-readable candidate list
9. Single-line candidate export
10. Versioned JSON candidate-state export
11. Structured JSON solve-result output
12. Output-to-file support
13. Initial stable renderer event objects and event log

Current user-visible grid formats:

- `pretty`
- `compact`
- `candidates`
- `candidate-list`
- `candidate-line`
- `candidate-json`

Character sets:

- `ASCII`
- `UNICODE_LIGHT`
- `UNICODE_DOUBLE`
- `UNICODE_HEAVY`

## Remaining Enhanced Output Work

Near-term:

- CSV and TSV result output
- One-line puzzle and solution output
- Optional color layer
- Event-aware text and JSON renderers
- Replay and solution-path formats

Longer-term:

- Mixed-weight Unicode grids
- HTML, Markdown, SVG, and other renderers
- Benchmark output through the common renderer framework
- Import of candidate-state interchange formats

## Event-System Plan

Patch 0013 establishes a versioned event object and ordered event log. Existing
text output remains unchanged.

Initial event types are:

- `pass_started`
- `strategy_result`
- `deduction`
- `restart`
- `pass_finished`
- `contradiction`
- `final_status`

Future patches may render these events as text, JSON, compact replay paths, or
benchmark data without changing solving logic.

## Parallel Sub-Projects

### 1. Enhanced Output Framework

 Current active branch. Continue incrementally and preserve merge safety.

### 2. Puzzle Input and Canonicalization

Planned work:

- canonical 81-character serialization
- normalization of supported blank markers
- validation and clearer input errors
- puzzle fingerprints
- duplicate detection
- import/export compatibility

### 3. Documentation and Example Corpus

Planned work:

- user-facing CLI guide
- comprehensive output examples
- strategy examples
- solved, stalled, and contradictory fixtures
- installation and troubleshooting material

### 4. Test Infrastructure and Fixtures

Planned work:

- reusable puzzle fixtures
- golden-output helpers
- renderer snapshot tests
- temporary-file helpers
- CLI integration-test utilities

### 5. Packaging and Developer Tooling

Planned work:

- focused Makefile targets
- CI configuration
- distribution and tarball checks
- release helpers
- documentation consistency checks

### 6. Theme System

Long-term presentation work:

- characters
- colors
- spacing and padding
- given-versus-derived value styling
- candidate highlighting
- terminal capability-aware defaults

## Merge Contract

Output work must not change strategy behavior, strategy ordering, candidate
logic, benchmark results, or difficulty calculations. Prefer additive modules,
small commits, wrappers, and stable public APIs. Existing output must not change
accidentally.
