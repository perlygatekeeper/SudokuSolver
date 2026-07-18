# Corpus Difficulty Distribution

This report summarizes the difficulty metadata stored in the compressed
canonical 17-clue master corpus:

```text
Puzzles/Master/sudoku17-master.jsonl.gz
```

The corpus contains 49,158 canonical minimal-clue puzzles. All records in this
snapshot use SudokuSolver difficulty rating method `2.7`.

These counts describe the canonical 17-clue source records. Generated puzzles
with additional revealed clues are rated separately after generation.

## Difficulty Labels

| Label | Count | Share |
| --- | ---: | ---: |
| Easy | 21,905 | 44.56% |
| Medium | 15,470 | 31.47% |
| Hard | 4,216 | 8.58% |
| Expert | 4,988 | 10.15% |
| Master | 2,579 | 5.25% |

## Difficulty Scores and Score Ceilings

The cumulative ceiling columns answer questions such as "how many corpus
records are at or below score 7?" This is the same numeric interpretation used
by strategy-ceiling generation constraints.

| Score | Count | Share | Count <= Score | Share <= Score |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 21,905 | 44.56% | 21,905 | 44.56% |
| 3 | 15,470 | 31.47% | 37,375 | 76.03% |
| 4 | 4,216 | 8.58% | 41,591 | 84.61% |
| 5 | 72 | 0.15% | 41,663 | 84.75% |
| 6 | 1,314 | 2.67% | 42,977 | 87.43% |
| 7 | 3,395 | 6.91% | 46,372 | 94.33% |
| 8 | 207 | 0.42% | 46,579 | 94.75% |
| 9 | 1,467 | 2.98% | 48,046 | 97.74% |
| 10 | 751 | 1.53% | 48,797 | 99.27% |
| 11 | 361 | 0.73% | 49,158 | 100.00% |

## Highest Required Strategy

Each row counts puzzles for which the listed strategy is the highest-scored
strategy required by SudokuSolver's successful solve.

| Highest Strategy | Count | Share |
| --- | ---: | ---: |
| Hidden Singles | 21,905 | 44.56% |
| Pointing / Claiming | 15,470 | 31.47% |
| Skyscraper | 2,822 | 5.74% |
| Naked Pairs | 2,383 | 4.85% |
| Hidden Pairs | 1,833 | 3.73% |
| XY-Wing | 1,299 | 2.64% |
| XY-Chains | 1,040 | 2.12% |
| AIC | 635 | 1.29% |
| Digit Forcing Chains | 361 | 0.73% |
| Empty Rectangle | 274 | 0.56% |
| X-Chains | 243 | 0.49% |
| Two-String Kite | 221 | 0.45% |
| Simple Coloring | 207 | 0.42% |
| Grouped L1-Wing | 183 | 0.37% |
| Grouped AIC | 116 | 0.24% |
| XYZ-Wing | 62 | 0.13% |
| Naked Triples | 37 | 0.08% |
| Hidden Triples | 19 | 0.04% |
| X-Wing | 16 | 0.03% |
| Unique Rectangle Type 3 | 11 | 0.02% |
| Unique Rectangle Type 1 | 6 | 0.01% |
| Unique Rectangle Type 2 | 6 | 0.01% |
| Naked Quads | 3 | 0.01% |
| Swordfish | 3 | 0.01% |
| Unique Rectangle Type 4 | 2 | 0.00% |
| Multi-Coloring | 1 | 0.00% |

## Notes

Difficulty labels are project-specific interpretations of solver statistics,
not universal Sudoku facts. Counts should be compared only within the same
rating method version.

The score ceiling table is especially useful for generation. A target such as
`--strategy-ceiling Skyscraper` maps to the score for that strategy, then
accepts generated puzzles rated at or below that score.
