# Multi-Coloring

## Purpose

Multi-Coloring extends Simple Coloring by comparing two separate strong-link
components for the same candidate digit. Each component is colored alternately
A and B, but the color names are local to that component.

## Rule 1: Color Collision

If one color in component 1 sees both colors of component 2, that color in
component 1 cannot be true. Were it true, both colors of component 2 would be
false, contradicting the strong-link chain. The impossible color is removed
from every cell carrying it in component 1.

## Rule 2: Color Wing

If one color from component 1 sees one color from component 2, those two colors
cannot both be true. Therefore at least one of their opposite colors must be
true. Any outside candidate that sees an opposite-color cell from each
component can be removed.

## Human-solving procedure

For one digit:

1. Find all conjugate pairs in rows, columns, and boxes.
2. Divide the resulting strong-link graph into disconnected components.
3. Color each component alternately with two colors.
4. Compare pairs of components for a color collision.
5. Compare pairs of components for a color wing and common-peer target.
6. Remove only candidates justified by one of those two rules.

Multi-Coloring is applied after Simple Coloring and X-Chains so smaller,
easier-to-explain single-component deductions are preferred first.
