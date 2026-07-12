# Simple Coloring Algorithm Notes

## Overview

For each digit from 1 through 9:

1. Find every conjugate pair in every row, column, and box.
2. Build an undirected graph whose nodes are candidate cells and whose edges are
   those strong links.
3. Split the graph into connected components.
4. Two-color each component by alternating colors across every edge.
5. Apply the color-wrap and color-trap rules.

## Shared infrastructure

`Sudoku::StrongLinks` provides:

* `strong_links_for_digit`
* `candidate_graph_for_digit`
* `connected_components`
* `cell_key`
* `cells_see_each_other`

This infrastructure is intentionally presentation-neutral so later strategies
such as X-Chains and multi-coloring can reuse it.

## Color Wrap

For each color in a component, compare every pair of cells with that color.  If
any pair sees each other through a row, column, or box, the color is
contradictory.  Remove the candidate from every cell carrying that color in the
component.

## Color Trap

Inspect candidate cells outside the current component.  If a cell sees at least
one color-A node and at least one color-B node, remove the candidate from that
cell.

A candidate belonging to a different connected component may still be trapped
by the current component; components are independent sources of the two-color
inference.

## Safety

A component that cannot be colored consistently is skipped.  An odd cycle of
strong links indicates either inconsistent candidate data or a contradiction
that should not be interpreted by Simple Coloring as an ordinary elimination.

Duplicate eliminations are suppressed by cell and digit.

## Complexity

The Sudoku graph is small: at most 81 candidate nodes per digit.  Graph
construction and breadth-first coloring are negligible compared with the rest
of the solve.  Color-wrap pair checks and color-trap visibility checks are also
bounded by the fixed board size.
