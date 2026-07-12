# Swordfish

## Human recognition

Choose one candidate. Look for three rows in which that candidate appears only
in two or three columns, with the combined positions confined to exactly three
columns. Those three rows must place the candidate somewhere in those three
columns, so the candidate can be removed from all other cells in the three
columns.

The pattern may be rotated: three columns and three cover rows work the same
way.

## Relationship to X-Wing

- X-Wing: two base units and two cover units.
- Swordfish: three base units and three cover units.
- Jellyfish: four base units and four cover units.

Unlike a common first impression, each Swordfish base row does not need to
contain all three cover positions. It may contain two or three, provided the
union across the three base units is exactly three cover units.

## Algorithm

For each candidate and orientation:

1. Keep base units with two or three candidate positions.
2. Choose every combination of three base units.
3. Form the union of their candidate positions.
4. Continue only when that union contains exactly three cover units.
5. Remove the candidate from other cells in those cover units.
6. Return no pattern when there are no eliminations.

## Common mistakes

- Requiring every base unit to use all three cover units.
- Accepting four cover units.
- Removing candidates from the fish cells themselves.
- Mixing candidate values.
- Returning duplicate eliminations discovered through overlapping patterns.
