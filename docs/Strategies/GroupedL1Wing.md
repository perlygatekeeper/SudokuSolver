# Grouped L1-Wing

A Grouped L1-Wing is a short, same-digit inference chain containing two strong
links joined by one weak link:

```text
A =S= B -W- C =S= D
```

At least one endpoint, `A` or `D`, must be true. A candidate that sees every
possible location represented by both endpoints can therefore be removed.

Unlike an ordinary two-strong-link chain, one or more nodes may represent a
**group** of candidate locations. For example:

```text
R2C3(7) =S= {R1C1,R1C2}(7) -W- R1C5(7)
          =S= {R2C4,R2C6}(7)
```

A grouped node means that the digit is true somewhere in that set; it does not
identify which member is true.

## Strong links

The strategy uses ordinary conjugate pairs and grouped links created at
row/box and column/box intersections. A grouped strong link exists when all
remaining locations for a digit in a unit divide into exactly two natural
segments, with at least one segment containing multiple cells.

## Weak links

Two grouped nodes are weakly linked only when every location in one node sees
every location in the other. This all-to-all rule is essential: seeing only
part of a group is not enough.

## Elimination rule

A target candidate is removed only when it sees every cell in both endpoint
nodes. Chain cells themselves are never elimination targets.
