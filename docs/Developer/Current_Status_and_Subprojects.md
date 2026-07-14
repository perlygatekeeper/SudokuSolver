# Current Status and Sub-Project Plans

## Repository Status

Current primary branch:

`main`

Current release milestone:

**v1.0.0 is tagged.**

The advanced-strategy and enhanced-output work are integrated. Version 1.0.0
solves the complete canonical collection of minimal 17-clue Sudoku puzzles:

```text
Puzzles processed : 49,158
Solved            : 49,158
Stalled           : 0
Contradictions    : 0
```

The first 1,000 puzzles remain a convenient development regression suite. The
full 49,158-puzzle corpus is the authoritative capability benchmark.

## Solver Status

The solver is deduction-driven and logic-first. It does not depend on
unrestricted recursive backtracking.

Implemented strategy families include:

- Singles and Pointing / Claiming
- Naked and Hidden Pairs, Triples, and Quads
- X-Wing, Swordfish, and Jellyfish
- XY-Wing, XYZ-Wing, and WXYZ-Wing
- Unique Rectangle Types 1 through 4
- Remote Pairs, Skyscraper, Two-String Kite, and Empty Rectangle
- Simple Coloring, Multi-Coloring, X-Chains, and XY-Chains
- AIC, Grouped L1-Wing, Grouped AIC, and Digit Forcing Chains

Reusable solver infrastructure includes:

- structured deduction objects
- strategy registry and restart policy
- fish framework
- ordinary and grouped strong-link discovery
- inference-node representation
- bounded hypothetical propagation
- contradiction detection
- statistics and difficulty models
- hint, explain, trace, and step-by-step support

Bounded hypothetical inference applies one candidate assumption, performs
limited deterministic propagation without nested assumptions, and returns a
structured proof result. This preserves the project's preference for finite,
auditable inference over unrestricted search.

## Enhanced Output Status

The enhanced-output branch has been merged into `main`.

Implemented grid formats:

- `pretty`
- `compact`
- `candidates`
- `candidate-list`
- `candidate-line`
- `candidate-json`

Implemented character sets:

- `ASCII`
- `UNICODE_LIGHT`
- `UNICODE_DOUBLE`
- `UNICODE_HEAVY`

Implemented structured result formats:

- `json`

Other completed output infrastructure:

- runtime grid-format discovery
- runtime character-set discovery
- runtime result-format discovery
- output-to-file support
- stable versioned renderer events
- ordered event logging
- output architecture and compatibility-contract documentation

The output subsystem remains intentionally separate from solving logic. New
renderers must not alter strategy behavior, strategy order, candidate state,
benchmark results, or difficulty calculations.

## Test Suite Status

The test suite uses a permanent three-digit numbering scheme:

```text
000-099  loading, cells, and grids
100-199  solver engine and deduction infrastructure
200-599  solving strategies
600-699  user-facing solver features
700-799  rendering and output
800-899  benchmarking and difficulty
900-999  regression coverage
```

This replaces the earlier two-digit numbering, which had accumulated several
collisions. New tests should be placed in the appropriate functional range
rather than assigned the next globally available number.

## Active Post-1.0 Sub-Projects

### 1. Performance and Aggregate Benchmarking

Planned work:

- profile the full-corpus solve
- reduce repeated candidate scans and avoid unnecessary allocations
- preserve deduction behavior while optimizing
- aggregate reports across all canonical benchmark files
- compare performance reproducibly between releases

### 2. Output and Renderer Expansion

Near-term possibilities:

- CSV and TSV result output
- explicit one-line puzzle and solution output
- event-aware text and JSON renderers
- replay and solution-path formats
- optional terminal color layer

Longer-term possibilities:

- mixed-weight Unicode grids
- Markdown, HTML, SVG, GUI, and web renderers
- benchmark output through common renderer contracts
- candidate-state interchange import

### 3. Puzzle Input, Canonicalization, and Identity

Planned work:

- canonical 81-character serialization
- common blank-marker normalization
- stronger validation and clearer input errors
- puzzle fingerprints
- duplicate detection
- symmetry canonicalization where useful

### 4. Difficulty and Solve Analysis

Planned work:

- calibrate difficulty against varied puzzle collections
- distinguish required techniques from incidental deductions
- add timing and effort metrics where useful
- preserve rating-version metadata
- support comparative solve reports

### 5. Documentation and Example Corpus

Planned work:

- expand the user-facing CLI guide
- provide comprehensive output examples
- maintain strategy examples and algorithm notes
- add installation and troubleshooting material
- keep release notes, roadmap, README, and current-status documents aligned

### 6. Test Infrastructure and Fixtures

Planned work:

- reusable puzzle fixtures
- golden-output and renderer snapshot helpers
- event-stream contract tests
- temporary-file helpers
- CLI integration-test utilities
- practical full-corpus release regression procedures

### 7. Packaging and Developer Tooling

Planned work:

- continuous integration
- distribution and tarball checks
- release helpers
- documentation consistency checks
- additional focused Makefile targets where warranted

### 8. Generation and User Interfaces

Long-term possibilities:

- puzzle generation and uniqueness verification
- difficulty-targeted generation
- interactive terminal use
- desktop GUI or web interface
- deduction-driven teaching mode

## Strategy Policy After 1.0

The current strategy set already completes the canonical corpus. New strategies
should be added only when they provide a demonstrated benefit: clearer proofs,
better performance, improved difficulty analysis, or reusable infrastructure.

Every new strategy should retain the established contract:

- no direct mutation while searching for a deduction
- structured placement or candidate-removal output
- human-readable explanation
- focused positive and negative tests
- benchmark and difficulty integration where appropriate
- a justified position in the strategy registry

## Merge Contract

Future work must preserve these invariants unless a deliberate, reviewed change
is being made:

- strategy behavior and ordering
- candidate-state correctness
- contradiction detection
- complete canonical-corpus coverage
- difficulty-version meaning
- renderer format contracts
- legacy output compatibility where promised

Prefer additive modules, small commits, stable public APIs, and independently
reviewable patches.
