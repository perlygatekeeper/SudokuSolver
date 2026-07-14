# Output Roadmap

## Phase 1

- [x] Add an extensible grid-character registry.
- [x] Add a reusable grid builder.
- [x] Preserve existing output compatibility while migrating grid renderers.

## Phase 2

- [x] Compact grid renderer (configurable empty-cell character).
- [x] Pretty grid renderer (string-returning).
- [x] Named grid-format registry and dispatcher.
- [ ] Expose grid-format discovery through the command line.

## Phase 3

- [x] Candidate grid renderer (string-returning).
- [ ] Candidate exports
  - [x] Human-readable
  - [x] Single-line
  - [x] JSON

## Phase 4

- [ ] JSON output
- [ ] CSV / TSV output
- [ ] One-line puzzle / solution output

## Phase 5

- [x] Unicode light, double-line, and heavy grid rendering
- [ ] Output to files
- [ ] Stable renderer events
- [ ] Optional color layer

## Parallel Projects

1. Enhanced output formats
2. Puzzle input and canonicalization
3. Documentation and example corpus
4. Test infrastructure and fixtures
5. Packaging and developer tooling

## Completed Infrastructure

- [x] Grid character-set registry
- [x] Reusable grid builder
- [x] String-returning pretty grid
- [x] String-returning compact grid
- [x] String-returning candidate grid
- [x] Named grid-format registry and dispatcher
- [x] CLI grid-format selection and discovery
