# Grouped AIC

Grouped Alternating Inference Chains extend ordinary AICs by allowing a chain
node to represent several candidate locations rather than one cell.

A grouped node means that the candidate is true somewhere in that group. The
solver only creates grouped strong links from complementary row/box and
column/box segments. Weak links involving groups require every location in one
node to conflict with every location in the other.

The strategy searches bounded alternating chains that begin and end with strong
links. When both endpoints represent the same digit, any outside candidate that
sees every possible location in both endpoints can be eliminated.

Grouped L1-Wing remains earlier in the solving order so short two-strong-link
patterns receive the more specific explanation.
