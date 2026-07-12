# Simple Coloring

## Purpose

Simple Coloring follows strong links for one candidate digit and assigns two
alternating colors to each connected component.  Because every strong link has
exactly one true endpoint, one of the two colors represents the true candidates
and the other represents the false candidates within that component.

The strategy uses two standard human-solving rules.

## Color Trap

An uncolored candidate that sees at least one candidate of each color can be
removed.  Whichever color is true, the uncolored candidate sees a true instance
of the digit.

## Color Wrap

If two candidates of the same color see each other, that color is impossible.
Every candidate of that color in the connected component can be removed.

## Strong links

A strong link exists when a digit appears in exactly two unsolved cells of a:

* row,
* column, or
* box.

Simple Coloring combines all such links for one digit into an undirected graph.
Each connected component is colored independently.

## Solver behavior

The strategy emits one structured candidate-removal deduction at a time.  Each
deduction records the complete colored component and explains whether the
elimination came from a color trap or a color wrap.
