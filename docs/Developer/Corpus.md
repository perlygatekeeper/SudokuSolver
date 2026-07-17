# The Definitive Corpus

## Introduction

The SudokuSolver corpus is more than a collection of puzzles. It is a
deterministic, reproducible catalogue of logical Sudoku identities. Every
published record represents a single canonical puzzle together with the
information required to understand its origin, reproduce its construction, and
identify it permanently.

The corpus exists to support benchmarking, research, software development, and
long-term archival. By assigning stable identities to logically equivalent
puzzles, SudokuSolver eliminates ambiguity while preserving complete
provenance.

This document explains the concepts behind the corpus. The precise layout of
published records is documented separately in **Corpus_Schema.md**.

---

## Design Goals

The corpus is guided by five principles:

- **Uniqueness** — Every logical puzzle appears exactly once.
- **Determinism** — The same inputs always produce the same corpus.
- **Reproducibility** — Anyone can rebuild the published corpus from authoritative source material.
- **Traceability** — Every canonical puzzle can be traced back to its original source.
- **Stability** — Published identifiers are intended to remain stable across future corpus releases.

---

## Why Canonicalization?

Many Sudoku puzzles that appear different are actually the same logical puzzle
viewed through symmetry transformations. Rotations, reflections, row and column
permutations, transposition, and digit relabeling alter appearance without
changing logical structure.

Canonicalization selects one unique representative from every equivalence
class, eliminating duplicate logical puzzles while preserving provenance.

---

## Equivalence Classes

An equivalence class is the complete set of puzzles reachable through the
supported Sudoku-preserving symmetry operations.

Every member shares the same logical puzzle and therefore the same canonical
representative.

---

## Canonical Puzzles

A canonical puzzle is the unique representative selected by the project's
canonicalization algorithm.

The current implementation chooses the lexicographically smallest member of
each equivalence class.

---

## Permanent Identity

Each canonical puzzle receives:

- a permanent Canonical ID,
- a deterministic fingerprint,
- associated metadata,
- provenance,
- and a witness transform.

These identifiers provide stable references suitable for research,
publications, benchmarking, and software development.

---

## Witness Transforms

Canonicalization never discards provenance.

A witness transform records the reversible sequence of symmetry operations that
maps a source puzzle to its canonical representative. Applying the inverse
transform reconstructs the original puzzle exactly.

---

## Building the Corpus

```
Source Puzzles
      |
      v
 Validation
      |
      v
Canonicalization
      |
      v
Canonical Puzzle
      |
 +----+-----------+
 |    |           |
ID Fingerprint Metadata
      |
      v
Published Corpus
```

Every stage is deterministic.

---

## Determinism and Reproducibility

Given identical source material and the same canonicalization algorithm,
SudokuSolver produces identical corpus records.

This reproducibility enables independent verification, stable benchmarks, and
long-term research.

---

## Published Releases

Each corpus release represents a reproducible snapshot of the project.

Future releases may extend metadata while preserving canonical identities
whenever practical.

---

## Future Directions

Planned enhancements include:

- richer metadata,
- symmetry classifications,
- published snapshots,
- additional research-oriented analysis.

## Query API

`Sudoku::Corpus` provides the public API for reading and querying the
authoritative JSONL master corpus.

```perl
my $corpus = Sudoku::Corpus->new;
my $record = $corpus->find_by_id('17C-000001');

my $query = $corpus->select(
    difficulty       => [ 'Expert', 'Master' ],
    score            => { min => 7 },
    highest_strategy => { not => 'Hidden Singles' },
);

my $ids = $query
    ->sort_by('score', direction => 'desc')
    ->limit(10)
    ->ids;
```

The query engine uses AND semantics across criteria and supports exact values,
sets, exclusions, numeric ranges, sorting, limiting, and deterministic random
selection. Convenience helpers such as `puzzles_by_difficulty`,
`puzzles_by_highest_strategy`, `puzzles_by_score`, and
`puzzles_with_symmetry` delegate to `select`.

## Symmetry-Randomized Generation

`Sudoku::Generator` can select a canonical corpus record deterministically and
apply a seeded Sudoku-preserving symmetry transform:

```perl
my $generated = Sudoku::Generator->new->symmetry_randomized(
    corpus_seed   => 20260717,
    symmetry_seed => 12345,
    criteria      => { difficulty => 'Master' },
);

say $generated->puzzle;
say $generated->solution;
say $generated->transform_shorthand;
```

The generated puzzle is equivalent to its canonical source puzzle. The result
records the canonical ID, fingerprint, corpus seed, symmetry seed, and explicit
transform shorthand so later replay can reconstruct the same variant.

## Controlled Clue Reveals

`Sudoku::Generator` can also reveal additional values from the transformed
solution while preserving every original transformed clue:

```perl
my $generated = Sudoku::Generator->new->controlled_reveals(
    corpus_seed   => 20260717,
    symmetry_seed => 12345,
    reveal_seed   => 67890,
    clue_count    => 30,
    criteria      => { difficulty => 'Master' },
);

say $generated->base_puzzle;       # transformed 17-clue puzzle
say $generated->puzzle;            # final puzzle with controlled reveals
say join ',', @{ $generated->reveal_cells };
```

The reveal seed is independent from the corpus and symmetry seeds. The result
stores explicit `RrCc` reveal cells, the requested target clue count, and the
final clue count so future replay can reconstruct the final puzzle from the
canonical source, transform shorthand, transformed solution, and stored reveal
list.

---

## Related Documentation

- **Readme.md** — Project overview.
- **Corpus_Schema.md** — Formal schema.
- **docs/Developer/** — Implementation details.
