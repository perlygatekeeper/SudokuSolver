# Multi-Coloring Algorithm Notes

## Shared infrastructure

`Sudoku::StrongLinks` now exports `color_component()`. Both Simple Coloring and
Multi-Coloring use the same breadth-first alternating-color implementation.
This prevents the two strategies from developing different interpretations of
the same candidate graph.

For each candidate digit, Multi-Coloring:

1. builds the strong-link graph,
2. finds connected components,
3. colors every non-conflicted component,
4. compares every unordered pair of components.

Odd-cycle components are ignored because a normal two-color interpretation is
not safe for them.

## Color collision

For a source color in component A, the implementation asks whether its cells
collectively see at least one color-A cell and at least one color-B cell in
component B. If so, assuming the source color true would make both colors of B
false. The complete source color is therefore false.

The collective test is valid because all cells assigned one color in a
connected strong-link component share the same truth state.

## Color wing

For each color pairing across two components, the implementation first looks
for a visible same-color contact. Because those two colors cannot both be true,
at least one opposite color must be true. It then scans outside candidates for
a cell seeing an opposite-color member from each component.

## Deduction handling

Deductions remove one candidate at a time through `Sudoku::Deduction`. A
cell-and-digit key suppresses duplicate eliminations when more than one
component comparison proves the same result. Reasons retain both complete
components as pattern cells and identify representative witnesses in the
human-readable text.

## Complexity

For each digit, graph construction remains small because Sudoku has only 81
cells. Component comparison is quadratic in the number of disconnected colored
components; each color-wing comparison scans the grid's 81 cells. This remains
bounded and appropriate for the current human-strategy solver.
