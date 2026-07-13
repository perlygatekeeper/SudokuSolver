# Grouped AIC Algorithm Notes

## Nodes

The graph uses `Sudoku::InferenceNode` objects. A node may contain one cell or a
natural group of cells for one digit.

## Strong links

Strong edges come from:

- bivalue cells;
- ordinary conjugate pairs in rows, columns, and boxes;
- grouped strong links at row/box and column/box intersections.

## Weak links

Different candidates in one cell are weakly linked. Same-digit nodes are
weakly linked only when they do not overlap and every location in one node sees
every location in the other.

## Search

A bounded depth-first search alternates strong and weak edges. The strategy
requires at least one grouped node in the path so ordinary AIC deductions remain
owned by `Sudoku::Strategy::AIC`.

For equal-digit endpoints, a target is removable only when it sees every cell
represented by both endpoint nodes.
