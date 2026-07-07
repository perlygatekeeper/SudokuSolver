# Sudoku Puzzle Symmetries

## Overview

Many Sudoku puzzles are mathematically equivalent under a set of
transformations that preserve both the puzzle and its unique solution.
These transformations form the Sudoku equivalence group.

The well-known collection of **49,151** minimal 17-clue puzzles contains
one representative from each equivalence class. Every other known
17-clue puzzle can be transformed into one of these representatives
using the transformations described below.

------------------------------------------------------------------------

## 1. Digit Relabeling

Replace each digit (1--9) with another digit, consistently throughout
the puzzle.

Example:

    1 ↔ 9
    2 ↔ 5
    ...

Number of possibilities:

    9! = 362,880

------------------------------------------------------------------------

## 2. Permute Rows Within a Band

A **band** consists of three adjacent rows:

    Rows 1–3
    Rows 4–6
    Rows 7–9

The three rows within each band may be reordered arbitrarily.

Number of possibilities:

    (3!)³ = 216

------------------------------------------------------------------------

## 3. Permute the Row Bands

The three bands themselves may be reordered.

Example:

    [1–3] [4–6] [7–9]

may become

    [7–9] [1–3] [4–6]

Number of possibilities:

    3! = 6

------------------------------------------------------------------------

## 4. Permute Columns Within a Stack

A **stack** consists of three adjacent columns:

    Cols 1–3
    Cols 4–6
    Cols 7–9

Columns within each stack may be permuted independently.

Number of possibilities:

    (3!)³ = 216

------------------------------------------------------------------------

## 5. Permute the Column Stacks

The three column stacks may themselves be reordered.

Number of possibilities:

    3! = 6

------------------------------------------------------------------------

## 6. Transpose the Puzzle

Reflect the puzzle across the main diagonal:

    (r, c) → (c, r)

This exchanges rows and columns while preserving Sudoku validity.

------------------------------------------------------------------------

## Total Size of the Equivalence Group

Combining all generators gives:

    9!
    × (3!)⁸
    × 2

which equals

    1,218,998,108,160

More than **1.2 trillion** symmetry operations.

------------------------------------------------------------------------

## Common Geometric Symmetries

Although these are combinations of the generators above, they are useful
to visualize:

-   Rotate 90°
-   Rotate 180°
-   Rotate 270°
-   Reflect horizontally
-   Reflect vertically
-   Reflect across the main diagonal
-   Reflect across the anti-diagonal

These do **not** enlarge the equivalence group; they are compositions of
the fundamental transformations.

------------------------------------------------------------------------

## Canonicalization

A useful future feature for SudokuSolver would be a **canonicalization**
routine.

Given any Sudoku puzzle, the routine would:

1.  Generate all equivalent puzzles under the symmetry group.
2.  Normalize digit labels.
3.  Select a unique canonical representative (for example, the
    lexicographically smallest encoding).

This would allow the solver to recognize when two apparently different
puzzles are actually equivalent. The 49,151 representative 17-clue
puzzles are precisely one canonical representative from each equivalence
class.
