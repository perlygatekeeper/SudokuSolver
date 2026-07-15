# Canonical Corpus and Generation Architecture

## Vision

SudokuSolver evolves from a solver into a complete Sudoku analysis,
classification, and reproducible puzzle-generation platform.

## Guiding Principles

-   Every canonical puzzle has exactly one stable identity.
-   Every generated puzzle is reproducible.
-   Metadata is human-readable.
-   Puzzle files remain editable with ordinary text editors.
-   All transformations are deterministic from stored metadata.

## Primary Modules

-   Sudoku::Canonical
-   Sudoku::Symmetry
-   Sudoku::Corpus
-   Sudoku::Generator

## Definitive Master Corpus

The master corpus contains one authoritative record for each of the
49,158 canonical 17-clue puzzles.

Each record stores:

-   Canonical ID
-   Digit-grouped coordinate encoding
-   Canonical puzzle
-   Solution
-   Difficulty score
-   Difficulty label
-   Difficulty version
-   Highest required strategy
-   Human-identifiable clue-pattern symmetries
-   Optional future metadata

## Coordinate Encoding

The encoding groups coordinates by digit (1--9).

For 17-clue puzzles:

-   34 coordinate characters
-   8 delimiters

Total: 42 characters.

The encoding must round-trip exactly.

## Query API

The primary interface is:

    $corpus->select(...)

Selection criteria are composable and combine with logical AND.

Example criteria include:

-   difficulty
-   highest_strategy
-   symmetry
-   clue_count
-   canonical_id
-   fingerprint

## Generation

Generation consists of:

Canonical puzzle → Symmetry transform → Controlled clue reveals →
Provenance metadata

## Invariants

-   decode(encode(P)) == P
-   canonicalize(canonicalize(P)) == canonicalize(P)
-   inverse(transform(P)) == P
-   replay(metadata) reproduces the original generated puzzle

## Human-identifiable Symmetries

-   rotation-180
-   rotation-90
-   reflection-horizontal
-   reflection-vertical
-   reflection-main-diagonal
-   reflection-anti-diagonal

These describe clue-pattern symmetry only.

## Long-term Goal

Use the canonical corpus as the foundation for reproducible puzzle
generation, analysis, benchmarking, teaching, and future research.
