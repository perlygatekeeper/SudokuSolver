# Difficulty Rating

## Overview

Sudoku difficulty is not determined only by the number of clues.

A puzzle with many clues may be difficult if it requires advanced strategies, while a sparse puzzle may be easy if it collapses quickly under basic logic.

SudokuSolver should eventually rate puzzle difficulty based on the solving strategies required and the complexity of the solving path.

---

## Guiding Principle

Difficulty should be based on how the puzzle is solved, not merely on how the puzzle looks.

A useful difficulty system should consider:

- hardest strategy required
- number of deductions
- number of strategy passes
- branching or guessing, if ever used
- complexity of explanations
- density of candidates during solving

---

## Strategy-Based Rating

A simple first model:

| Rating | Required Techniques |
|--------|---------------------|
| Easy | Naked Singles, Hidden Singles |
| Moderate | Pointing / Claiming |
| Intermediate | Naked Pairs, Hidden Pairs |
| Hard | X-Wings |
| Expert | Remote Pairs, Coloring, Wings |
| Extreme | Requires trial, contradiction, or search |

This model is easy to understand and easy to test.

---

## Weighted Scoring Model

A later model could assign point values to each deduction.

Example:

| Strategy | Suggested Weight |
|----------|------------------|
| Naked Single | 1 |
| Hidden Single | 2 |
| Pointing / Claiming | 4 |
| Naked Pair | 6 |
| Hidden Pair | 8 |
| X-Wing | 15 |
| Remote Pair | 25 |
| Guess / Search | 100+ |

The total difficulty score would be the sum of all deductions made during solving.

Example:

32 Naked Singles × 1 = 32
12 Hidden Singles × 2 = 24
3 Naked Pairs × 6 = 18
1 X-Wing × 15 = 15

Total score = 89

This can be mapped to user-facing categories.

---

## Hardest-Strategy Model

Another useful rating is the hardest required strategy.

Example:

Puzzle A:
Uses 80 Naked Singles and 1 X-Wing.
Hardest strategy: X-Wing.

Puzzle B:
Uses 30 Naked Singles only.
Hardest strategy: Naked Single.

This model is simple and intuitive, but it may miss puzzles that are long and tedious without requiring advanced techniques.

---

## Hybrid Rating

The best long-term approach may combine:

1. Hardest strategy required.
2. Total weighted score.
3. Number of solving passes.
4. Number of unresolved candidates over time.

Example rating object:

{
    label            => 'Hard',
    score            => 89,
    hardest_strategy => 'X-Wing',
    steps            => 48,
    guesses          => 0,
}

---

## Explanation Complexity

Since SudokuSolver is intended to become an explainable solver, difficulty should also consider how hard a step is to explain.

A strategy that is easy to apply mechanically may still be hard for a human to understand.

Future difficulty scoring could include:

- number of cells involved
- number of units involved
- length of chain
- number of candidates eliminated
- whether the explanation requires visual pattern recognition

---

## Proposed API

Possible future interface:

my $result = $solver->solve;

my $rating = $result->difficulty;

Or:

my $rating = Sudoku::Difficulty->rate($solve_log);

A rating could include:

{
    label       => 'Intermediate',
    score       => 47,
    hardest     => 'Hidden Pair',
    steps       => 33,
    strategies  => {
        naked_single  => 18,
        hidden_single => 10,
        naked_pair    => 3,
        hidden_pair   => 2,
    },
}

---

## Required Solver Support

Difficulty rating requires a solve log.

Each deduction should eventually record:

- strategy name
- affected cell
- affected candidate or value
- explanation
- before/after candidate state
- pass number
- whether progress was made

Without this data, difficulty rating will be approximate.

---

## Testing Plan

Suggested tests:

80_difficulty_basic.t
81_difficulty_weighted.t
82_difficulty_strategy_counts.t
83_difficulty_regressions.t

Tests should verify:

- simple puzzles are rated easy
- puzzles requiring pairs are rated higher than single-only puzzles
- hardest strategy is reported correctly
- score is deterministic
- equivalent solving paths produce equivalent ratings

---

## Caution

Difficulty rating is partly subjective.

Different human solvers find different techniques easy or hard. Therefore, SudokuSolver's difficulty labels should be documented as project-specific rather than universal.

The most important property is consistency.

If SudokuSolver rates one puzzle harder than another, it should be able to explain why.
