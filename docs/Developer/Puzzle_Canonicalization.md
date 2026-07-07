# Puzzle Canonicalization

## Overview

Sudoku puzzles can appear different while being mathematically equivalent under Sudoku symmetries.

Canonicalization is the process of transforming any puzzle into a single, predictable representative form.

This allows SudokuSolver to recognize equivalent puzzles, compare puzzles reliably, and work with reduced puzzle collections such as the 49,151 representative 17-clue puzzles.

---

## Relationship to Symmetry

This document builds on `Sudoku_Symmetries.md`.

The relevant transformations include:

- digit relabeling
- row permutations within bands
- band permutations
- column permutations within stacks
- stack permutations
- transposition

Together these transformations define the equivalence class of a puzzle.

Two puzzles are equivalent if one can be transformed into the other using these operations.

---

## Canonical Form

A canonical form is a chosen representative from an equivalence class.

One practical rule is:

The canonical form is the lexicographically smallest puzzle string reachable through valid Sudoku symmetries.

A puzzle string might use:

0 or . for empty cells
1-9 for clues

Example:

000000010400000000020000000000050407008000300001090000300400200050100000000806000

---

## Why Canonicalization Is Useful

Canonicalization can support:

- duplicate detection
- puzzle database cleanup
- comparison against known puzzle collections
- recognizing equivalent 17-clue puzzles
- testing symmetry operations
- future puzzle generation
- difficulty-analysis caching

If two puzzles have the same canonical form, they are equivalent.

---

## Basic Algorithm

A straightforward canonicalization algorithm:

1. Start with a puzzle string.
2. Generate equivalent puzzles under all allowed transformations.
3. Normalize digit labels for each generated puzzle.
4. Select the lexicographically smallest normalized string.

Pseudo-code:

best = undef

for each structural_transform in sudoku_symmetry_group:
    transformed = apply_transform(puzzle, structural_transform)
    normalized  = normalize_digits(transformed)

    if best is undef or normalized lt best:
        best = normalized

return best

---

## Digit Normalization

Digit normalization relabels digits in order of first appearance.

Example:

Original:
800000003000700000004000000...

First digit seen: 8 -> 1
Next digit seen: 3 -> 2
Next digit seen: 7 -> 3
Next digit seen: 4 -> 4

This produces a normalized digit labeling independent of the original symbols.

Digit normalization dramatically reduces the need to try all `9!` digit permutations.

---

## Structural Transformations

The structural transformations are the row/column/box-preserving operations:

row permutations within bands
band permutations
column permutations within stacks
stack permutations
transpose

These transformations preserve Sudoku validity.

The total structural count excluding digit relabeling is:

(3!)⁸ × 2 = 3,359,232

That is large, but still much smaller than including all digit relabelings naively.

---

## Performance Considerations

A naive canonicalization routine may be expensive.

Possible optimizations:

- normalize digits immediately after each structural transform
- prune transforms using clue positions
- cache intermediate band/stack permutations
- canonicalize clue pattern before digit content
- compare incrementally rather than generating all strings
- use known canonicalization algorithms from Sudoku research

For early project development, correctness is more important than speed.

---

## Proposed API

Possible future interface:

use Sudoku::Canonical;

my $canonical = canonicalize_puzzle($puzzle_string);

Or object-oriented:

my $canonical = Sudoku::Canonical->new(
    puzzle => $puzzle_string,
)->canonical_form;

Useful helper functions:

normalize_digits($puzzle)
transpose_puzzle($puzzle)
permute_rows($puzzle, @row_order)
permute_columns($puzzle, @column_order)
canonicalize_puzzle($puzzle)
equivalent_puzzles($puzzle)

---

## Testing Plan

Suggested tests:

70_symmetry_transforms.t
71_digit_normalization.t
72_canonicalization.t
73_equivalence.t

Test cases should verify:

- transposition preserves clues correctly
- row and column permutations preserve puzzle structure
- digit normalization is deterministic
- equivalent puzzles canonicalize to the same string
- non-equivalent puzzles usually canonicalize differently

---

## Relationship to the 49,151 17-Clue Puzzles

The files:

Puzzles/sudoku17.txt
Puzzles/sudoku17-ml.txt

contain representative 17-clue puzzles.

These are unique up to Sudoku symmetries. Canonicalization would allow SudokuSolver to compare an arbitrary 17-clue puzzle against this representative set.

Future workflow:

input puzzle
    ↓
canonicalize
    ↓
look up canonical form in representative database
    ↓
identify equivalence class

---

## Long-Term Goal

Canonicalization is not required for solving ordinary puzzles.

However, it would make SudokuSolver more powerful as a research and analysis tool, especially for:

- 17-clue puzzle studies
- puzzle collection management
- duplicate detection
- puzzle generation
- symmetry-aware benchmarking
