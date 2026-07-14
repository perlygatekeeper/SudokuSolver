# Output Contracts

## Purpose

These contracts govern all work performed on the `feature/enhanced-output-methods`
branch.

## Contract 1 — Orthogonality

The output subsystem shall remain independent of solving logic.

Changes to rendering must **not** change:

- strategy behavior
- strategy ordering
- candidate generation
- deductions
- benchmark results
- difficulty calculations

## Contract 2 — Merge Safety

The enhanced-output branch shall avoid architectural changes that complicate
merging into the active strategy-development branch.

Prefer:

- new renderer methods
- wrapper methods
- additive APIs
- isolated modules
- small commits

Avoid unnecessary refactoring of Solver, Grid, or strategy modules.

## Contract 3 — Backward Compatibility

Existing output is currently part of the public API because many regression tests
validate textual output.

Existing output should remain unchanged unless corresponding tests are updated as
part of an intentional change.

New formats should generally be introduced as opt-in features.

## Contract 4 — Renderers Return Strings

Renderer methods should return strings rather than print directly.

The caller decides whether the string is:

- printed
- written to a file
- compared in tests
- embedded in JSON
- colored
- otherwise processed

## Contract 5 — Presentation Separation

The solver produces data.

Renderers produce presentation.

The solver should never depend on how output is displayed.

## Contract 6 — Candidate Preservation

Future candidate export formats must preserve the complete candidate state of
all 81 cells without loss of information.

