# Jellyfish algorithm notes

`Sudoku::Strategy::Jellyfish` calls `Sudoku::Fish::find_fish_patterns($grid, 4)`.
For each digit and orientation, the shared helper:

1. collects base units containing two through four candidate positions;
2. examines every four-base-unit combination;
3. requires the union of cover positions to contain exactly four units;
4. returns candidate targets in those cover units outside the selected bases.

Duplicate target/value deductions are suppressed by the strategy. X-Wing and
Swordfish run first, preserving the more specific explanation for smaller fish.
