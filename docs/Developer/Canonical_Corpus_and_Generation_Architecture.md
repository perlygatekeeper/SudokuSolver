# Canonical Corpus and Generation Architecture

## Purpose

Version 1.2.0 expands SudokuSolver from a logic-first solver into a platform
for puzzle representation, classification, corpus queries, reproducible
symmetry randomization, and controlled puzzle generation.

The work is divided into nine phases so each layer can be tested and stabilized
before the next depends on it.

## Core Principles

1. The normalized 81-character puzzle string remains the initial source of
   truth.
2. Derived representations must be deterministic.
3. Stored puzzle metadata must remain readable in an ordinary text editor.
4. Randomized operations must be reproducible from stored seeds and explicit
   operation logs.
5. Canonical IDs must not depend on difficulty ordering or other mutable
   metadata.
6. Difficulty data must always name its rating version.
7. Corpus selection must use one composable query engine rather than a growing
   collection of incompatible filters.

## Phase 1 Contract: Puzzle Representation

Phase 1 produces a stable encoding from a normalized puzzle. It is deliberately
encode-only.

### Source representation

The accepted source representation is exactly 81 characters containing only
`0` through `9`:

- `1` through `9` are clues;
- `0` is an empty cell.

Input normalization remains the responsibility of the existing puzzle-input
layer. The coordinate encoder rejects dots, underscores, spaces, and other
blank markers rather than silently normalizing them.

### Digit-grouped coordinate encoding

The encoding contains nine groups in fixed digit order:

```text
1-group-2-group-3-group-4-group-5-group-6-group-7-group-8-group-9-group
```

Each clue is represented by two decimal characters:

```text
RC
```

where `R` is row 1–9 and `C` is column 1–9. Coordinates within each digit group
are emitted in row-major order. The digit itself is omitted because the group
position identifies it.

Exactly eight hyphens separate the nine groups. Empty digit groups are
represented by adjacent delimiters or by an empty first or last field.

Example:

```text
2953-364892-384672-5579-63-6891-8296-85-89
```

For a puzzle containing `N` clues, the encoded length is:

```text
2N + 8
```

A 17-clue puzzle therefore always produces 42 characters.

### Phase 1 public API

```perl
use Sudoku::CoordinateEncoding qw(
    validate_puzzle_string
    clue_count
    clue_locations
    encode_puzzle
);
```

`encode_puzzle` accepts either a normalized puzzle string or an object exposing
`as_puzzle_string`.

`clue_locations` returns row-major entries containing `digit`, `row`, and
`column`, all using human-facing 1-based coordinates.

### Deliberate exclusions

Phase 1 does not include:

- coordinate decoding;
- arbitrary encoding parsing;
- canonization;
- stable canonical IDs;
- symmetry transforms; or
- puzzle reconstruction from coordinate metadata.

Decoding belongs in Phase 4, when the definitive corpus creates a genuine need
to reconstruct and verify stored records.

### Phase 1 validation

The implementation must prove that:

- each source puzzle contains exactly 81 normalized cells;
- generated encodings contain exactly nine groups;
- generated coordinate data contains only row/column digits 1–9;
- generated coordinate data contains complete two-character pairs;
- encoded length equals `2 * clue_count + 8`;
- every canonical corpus puzzle contains exactly 17 clues;
- all 49,158 corpus puzzles encode successfully; and
- no two source-corpus puzzles produce the same encoding.

The full-corpus validation entry point is:

```bash
make corpus-audit
```

## Phase 2: Sudoku Symmetry Model

A symmetry transform records:

- a digit permutation;
- one row permutation for each source band;
- one column permutation for each source stack;
- a band permutation; and
- a stack permutation.

All coordinate permutations are stored as zero-based source-to-target maps.
For example, `bands => [2, 0, 1]` sends source band 0 to target band 2,
source band 1 to target band 0, and source band 2 to target band 1. Digit
permutations are one-based source-to-target maps, so the first entry is the
new value for source digit 1.

The first Phase 2 increment provides:

```perl
my $transform = Sudoku::Symmetry->new(
    digits => [ 2, 1, 3, 4, 5, 6, 7, 8, 9 ],
    bands  => [ 1, 2, 0 ],
    rows   => [ [2,0,1], [1,2,0], [0,2,1] ],
    stacks => [ 2, 0, 1 ],
    cols   => [ [1,2,0], [2,0,1], [0,1,2] ],
);

my $variant = $transform->apply_puzzle($puzzle);
my $shorthand = $transform->serialize;
```

Stable shorthand uses this form:

```text
D=213456789;B=120;R=201|120|021;S=201;C=120|201|012
```

The second Phase 2 increment adds inversion and composition:

```perl
my $inverse  = $transform->inverse;
my $restored = $inverse->apply_puzzle($variant);

# Composition order is explicit: the receiver is applied first, then $next.
my $combined = $transform->compose($next);
```

Required guarantees include:

```text
T.inverse.apply(T.apply(P)) == P
T.compose(U).apply(P)       == U.apply(T.apply(P))
T.compose(T.inverse)        == identity
```

The final Phase 2 increment adds shorthand parsing and deterministic seeded
generation:

```perl
my $replayed = Sudoku::Symmetry->from_shorthand($transform->serialize);
my $random   = Sudoku::Symmetry->random(seed => 384729184);
```

Shorthand parsing is strict and must reproduce the same transform byte for
byte when serialized again. Seeded generation uses a private deterministic
32-bit PRNG and must not read from or modify Perl's global `rand()` state.
The generated transform is pinned by regression tests so a given integer seed
continues to produce the same shorthand throughout the v1.2.x line.

Phase 2 is complete when transforms support application, inversion,
composition, serialization, parsing/replay, and deterministic random
construction.

## Phase 3: Canonization and Identity

Canonization maps every symmetry-equivalent puzzle to one deterministic
representative. It is implemented incrementally so each normalization layer is
independently testable.

The first layer is the digit-normal form. The normalized puzzle is scanned in
row-major order. The first previously unseen clue digit is renamed to 1, the
next unseen digit to 2, and so on. Digits absent from the puzzle receive the
remaining target values in source-digit order so the recorded mapping is still
a complete, invertible permutation.

`Sudoku::Canonical->digit_normal_form($puzzle)` returns a
`Sudoku::Canonical::Result` containing:

- `puzzle` — the normalized 81-character puzzle string;
- `transform` — the exact `Sudoku::Symmetry` transform that produced it; and
- `stage` — currently `digit-normal`.

The digit layer guarantees:

```text
normalize_digits(normalize_digits(P)) == normalize_digits(P)
normalize_digits(D.apply(P))          == normalize_digits(P)
```

for every valid digit permutation `D`. It does not yet canonicalize spatial
row, column, band, or stack equivalents.

The second layer is the row-normal form. It enumerates every legal combination
of the three band permutations and the three independent row-within-band
permutations: `3! * (3!)^3 = 1,296` row-side transforms. Each transformed
puzzle is digit-normalized, and the lexicographically smallest resulting
81-character string is selected. The returned transform composes the winning
row-side transform with its digit-normalization transform.

`Sudoku::Canonical->row_normal_form($puzzle)` therefore guarantees:

```text
normalize_rows(normalize_rows(P)) == normalize_rows(P)
normalize_rows(R.apply(P))        == normalize_rows(P)
normalize_rows(D.apply(P))        == normalize_rows(P)
```

for every legal row-side transform `R` and digit permutation `D`. This is still
not the full canonical representative because column, stack, and transpose-like
search decisions have not yet been incorporated.

Full canonization must ultimately guarantee:

```text
canonicalize(canonicalize(P)) == canonicalize(P)
canonicalize(transform(P))    == canonicalize(P)
```

Permanent canonical IDs are assigned only after canonical ordering is stable.
The canonical coordinate encoding becomes the content-derived fingerprint.

### Canonical staging index

Before Phase 4 assigns permanent IDs, `bin/build-canonical-index.pl` creates a
reproducible TSV staging index. Each record contains:

```text
source ordinal
source puzzle
canonical puzzle
canonical fingerprint
witness transform shorthand
```

The builder may use multiple forked workers, but its output must be byte-for-byte
identical for the same input regardless of worker count. The parent process sorts
records by source ordinal, replays every witness transform, verifies every
fingerprint, rejects duplicate canonical fingerprints, and replaces the output
atomically only after all checks pass. The staging index is an intermediate
verification artifact; Phase 4 derives stable `17C-NNNNNN` IDs from canonical
ordering rather than source order.


### Permanent canonical identity assignment

Phase 4 assigns stable IDs only after staging records have been verified.
`bin/build-canonical-identities.pl` sorts records by the complete canonical
81-character puzzle string and assigns sequential IDs in that order:

```text
17C-000001
17C-000002
...
17C-049158
```

Source-file order, worker count, difficulty, strategy metadata, and later corpus
enrichment must not affect these IDs. Reordering staging records therefore
produces byte-identical identity output. The identity index retains source
ordinal, source puzzle, and witness transform as provenance, but canonical
ordering alone determines the permanent ID.

### Full canonical search and exact pruning

The correctness baseline considers all 1,296 row-family transforms crossed with
all 1,296 column-family transforms. Each spatial candidate is digit-normalized
and compared lexicographically.

The optimized implementation preserves that exact search result while pruning
in stages:

1. Determine the globally minimal possible first row and retain only column
   transforms capable of producing it for each source row.
2. Evaluate the first 27 characters using only the 18 distinct leading-band
   arrangements: three possible source bands times six row orders. The full
   1,296 row-family list repeats each leading arrangement 72 times while
   arranging the remaining bands, so avoiding those repetitions is exact.
3. Evaluate the first 54 characters using only the 216 distinct ordered
   two-band arrangements. Complete row-family specifications repeat each such
   prefix six times while arranging the final band.
4. Construct complete 81-character candidates only for transform pairs tied
   through the globally minimal first two bands.

The optimized result must remain byte-for-byte identical to the exhaustive
baseline and retain the exact invertible witness transform. Performance can be
measured with:

```bash
make canonical-benchmark
make canonical-benchmark LIMIT=100
```

### Canonical fingerprint

The canonical fingerprint is the digit-grouped coordinate encoding of the fully
canonical puzzle:

```text
fingerprint(P) = encode_puzzle(canonicalize(P))
```

For a 17-clue puzzle it is exactly 42 characters. Unlike a shortened hash, the
fingerprint is collision-free for the encoded puzzle representation,
human-readable, and directly derived from clue locations and values. It is
invariant under every supported digit, row, column, band, and stack symmetry.

The fingerprint and the permanent corpus ID serve different purposes:

- the fingerprint is content-derived and remains stable when corpus ordering or
  metadata changes;
- the corpus ID is a compact sequential label assigned only after canonical
  ordering has been generated and verified.

`Sudoku::Canonical::Result->fingerprint` is valid only for results whose stage
is `canonical`. Intermediate digit-, row-, and column-normal forms may expose a
coordinate encoding, but must not present it as a canonical fingerprint.


### Column-side normal form

`Sudoku::Canonical->column_normal_form($puzzle)` enumerates all 1,296
combinations of stack order and column order within each stack. Every candidate
is digit-normalized before lexical comparison. The result stage is
`column-normal`, and the result records the exact composed transform that maps
the source puzzle to the selected representative.

The column-normal layer guarantees:

- idempotence;
- invariance under digit permutations;
- invariance under stack and column-within-stack permutations; and
- an exact invertible witness transform.

This remains a one-sided normalization layer. Full canonization must search or
otherwise reconcile both row-side and column-side symmetry families.

## Phase 4: Definitive Master Corpus

The authoritative corpus contains one record for every canonical 17-clue
puzzle. Records include identity, puzzle, solution, versioned difficulty,
highest strategy, and simple human-identifiable clue-pattern symmetries.

Supported pattern symmetries are:

- `rotation-180`
- `rotation-90`
- `reflection-horizontal`
- `reflection-vertical`
- `reflection-main-diagonal`
- `reflection-anti-diagonal`

This is clue-mask analysis only; full automorphism-group analysis is out of
scope.

Phase 4 also adds coordinate decoding and round-trip corpus verification.

## Phase 5: Corpus Query Contract

The primary public query interface is composable:

```perl
my $query = $corpus->select(
    difficulty       => 'Expert',
    highest_strategy => 'XY-Chain',
    symmetry         => 'rotation-180',
);
```

Multiple criteria use AND semantics. Individual criteria may support ranges,
lists of accepted values, and explicit exclusions.

The query result may then be sorted, limited, or reproducibly randomized.
Convenience methods such as `puzzles_by_difficulty` delegate to this common
selection engine.

## Phases 6–9: Generation and Replay

Generation follows this pipeline:

```text
canonical corpus record
    -> seeded symmetry transform
    -> seeded controlled clue reveals
    -> difficulty validation
    -> human-readable provenance file
```

Symmetry and clue reveals use separate seeds. The explicit transform and reveal
list are stored alongside the seeds so replay remains stable even if random
selection internals change in a later release.

The final replay invariant is:

```text
replay(metadata) == originally generated puzzle
```


## Full Canonical Form Baseline

The Phase 3 correctness baseline considers the Cartesian product of the legal
row-side and column-side spatial families:

```text
1,296 row-family transforms
× 1,296 column-family transforms
= 1,679,616 spatial candidates
```

Every spatial candidate is digit-normalized before lexical comparison. The
smallest normalized 81-character string is the canonical representative. The
result records the exact composed symmetry transform that maps the original
puzzle to that representative.

Required contracts:

```text
canonicalize(canonicalize(P)) == canonicalize(P)
canonicalize(T.apply(P)) == canonicalize(P)
result.transform.apply(P) == result.puzzle
result.transform.inverse.apply(result.puzzle) == P
```

This exhaustive implementation is the reference definition for correctness.
It is intentionally retained as a baseline while later Phase 3 work introduces
pruning or indexing suitable for all 49,158 corpus records. Optimized
implementations must produce byte-identical canonical strings and equivalent
witness transforms.


## Canonical Search Pruning

The exhaustive full canonical form remains the correctness definition. The
optimized search first determines the globally smallest possible digit-normalized
first row across all source rows and legal column-family transforms. During the
full search, it considers only transform pairs capable of producing that first
row. This pruning is exact: a candidate with a larger first row cannot be the
lexicographically smallest 81-character representative. Prefix comparison then
stops remaining candidates as soon as they exceed the current best result.
