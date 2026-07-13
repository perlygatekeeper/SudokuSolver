# AIC Algorithm Notes

1. Build a graph of `(cell, candidate)` nodes.
2. Add strong edges for unit conjugate pairs and bivalue cells.
3. Add weak edges for mutually exclusive candidates in a cell or unit.
4. Discard nodes that do not participate in a strong edge.
5. Run a bounded depth-first search, beginning with a strong edge and then
   alternating weak and strong edges.
6. After each strong edge, compare the current endpoint with the starting node.
7. If both endpoints represent the same digit in different cells, eliminate
   that digit from every outside cell that sees both endpoints.
8. Return structured deductions without mutating the grid.

The nine-node bound controls runtime and is intentionally documented so later
profiling can tune it independently of the logical rule.
