# Jellyfish

A Jellyfish is a size-four basic fish. For one candidate, choose four base rows
(or four base columns) whose candidate locations are confined to the same four
cover columns (or rows). The candidate must occupy those four cover units in the
base units, so it can be removed from all other cells in the cover units.

The solver reports each removal as a structured deduction and identifies the
candidate, base units, cover units, pattern cells, and target cell.
