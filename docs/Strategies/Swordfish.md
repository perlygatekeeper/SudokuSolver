# Swordfish

Swordfish is a size-3 fish strategy. For one candidate, three base rows confine
that candidate to the same three cover columns, or three base columns confine it
to the same three cover rows. The candidate may then be removed from every
other cell in those cover units.

`Sudoku::Strategy::Swordfish` is discovery-only. It returns
`Sudoku::Deduction` objects and never mutates the grid directly.

The implementation accepts two or three candidate positions in each base unit,
requires the union of cover positions to contain exactly three units, and
returns deductions only when actual eliminations exist.
