# Master Corpus JSONL Schema

## Status

This document defines schema version `1.0` of the authoritative SudokuSolver
canonical 17-clue corpus.

The authoritative logical artifact is the master JSONL stream. A checkout may
store it as plain JSONL or gzip-compressed JSONL:

```text
Puzzles/Master/sudoku17-master.jsonl
Puzzles/Master/sudoku17-master.jsonl.gz
```

Each non-blank line is one complete JSON object. Records are sorted by
`identity.canonical_id`.

## Authority and build artifacts

The JSONL record stream is the source of truth. These TSV files are
intermediate build artifacts:

```text
sudoku17-canonical-index.tsv
sudoku17-canonical-identities.tsv
sudoku17-canonical-solutions.tsv
```

They remain useful for inspection, restartable processing, and regression
comparison, but public corpus consumers should read the JSONL master.

## Record shape

```json
{
  "schema": {
    "name": "SudokuSolver canonical corpus",
    "version": "1.0"
  },
  "identity": {
    "canonical_id": "17C-000001",
    "fingerprint": "...",
    "canonical_puzzle": "..."
  },
  "solution": "...",
  "clue_count": 17,
  "canonicalization": {
    "scheme": "SudokuSolver",
    "scheme_version": "1.0"
  },
  "difficulty": {
    "scheme": "SudokuSolver",
    "scheme_version": "2.7",
    "score": 11,
    "label": "Master",
    "highest_strategy": "Digit Forcing Chains"
  },
  "pattern_symmetries": ["rotation-180"],
  "provenance": {
    "source_ordinal": 1,
    "source_puzzle": "...",
    "witness_transform": "D=...;B=...;R=...;S=...;C=..."
  }
}
```

## Version independence

The following versions are independent:

- `schema.version` versions the JSON record contract.
- `canonicalization.scheme_version` versions the canonical-representative
  definition.
- `difficulty.scheme_version` versions the difficulty-rating method.
- The SudokuSolver application release version is not used as a substitute for
  any of these.

The current difficulty implementation has its own rating version. Master
records store the rating method's actual version so future rating methods can
revise analysis metadata without changing canonical IDs.

## Required invariants

For every record:

- `canonical_id` is unique and in ascending canonical order.
- `fingerprint` equals the coordinate encoding of `canonical_puzzle`.
- `canonical_puzzle` contains exactly 17 clues.
- `solution` contains exactly 81 digits from 1 through 9.
- Every canonical clue agrees with the solution.
- Applying `witness_transform` to `source_puzzle` reproduces
  `canonical_puzzle` exactly.
- `difficulty.scheme_version`, `difficulty.score`, and `difficulty.label` are
  populated from the versioned SudokuSolver difficulty model.
- `difficulty.highest_strategy` is either the highest-ranked solving strategy
  used by the versioned analysis or `null` if no strategy was required.
- `pattern_symmetries` is an array containing only documented clue-mask
  symmetry names.
- Publication is atomic: a failed build must not replace the prior master file.

## Derived views

The JSONL file remains authoritative. The release process may publish derived
views such as:

```text
Puzzles/Master/sudoku17-master.tsv
Puzzles/Master/sudoku17-master-summary.txt
```

These files are generated from the JSONL master and may be regenerated at any
time.
