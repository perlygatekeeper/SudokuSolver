# Grouped L1-Wing Algorithm Notes

## Purpose

Add a bounded first use of grouped candidate nodes without broadening the full
AIC search. The strategy recognizes only a strong-weak-strong same-digit chain.

## Candidate nodes

`Sudoku::InferenceNode` represents one digit in either one cell or a canonical
ordered group of cells. It provides stable keys, labels, overlap checks, and a
single/group distinction.

## Grouped strong-link generation

`Sudoku::StrongLinks::grouped_strong_links_for_digit()` examines:

- candidate rows within each box;
- candidate columns within each box;
- candidate boxes within each row;
- candidate boxes within each column.

If a unit's candidate locations occupy exactly two such segments, the two
segments form a strong link. Links containing only two singleton nodes are
left to the existing ordinary conjugate-pair finder.

## Search

For each digit:

1. Combine ordinary and grouped strong links.
2. Orient a first link as `A =S= B`.
3. Orient a second link as `C =S= D`.
4. Require an all-to-all weak link between `B` and `C`.
5. Require at least one grouped node and no overlapping chain nodes.
6. Remove the digit from candidates that see every location in `A` and `D`.

The bounded four-node form keeps the correctness surface and runtime small.
The grouped-node infrastructure can later support Grouped X-Chains and
Grouped AIC.

## Safety conditions

- Group members all represent the same digit.
- Strong-link groups are disjoint and exhaust the candidate locations in their
  generating unit.
- Weak links use all-to-all visibility.
- Targets use all-to-all visibility to both endpoints.
- Any chain with overlapping logical nodes is rejected.
