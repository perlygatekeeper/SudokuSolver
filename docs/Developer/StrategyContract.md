# Strategy Contract

Solving strategies are the long-term home for individual Sudoku techniques.

Examples include:

* Naked Singles
* Hidden Singles
* Pointing / Claiming
* Naked Pairs
* Hidden Pairs
* X-Wing
* Remote Pairs

## Future Strategy Responsibilities

Each strategy should be able to:

1. inspect a grid,
2. determine whether the technique applies,
3. make one or more safe deductions,
4. report whether it made progress,
5. explain why the deduction was valid.

A future interface may look like:

```perl
my $result = $strategy->apply($grid);

if ($result->changed) {
    say $result->explanation;
}
```

This is not a required v0.5.x implementation. It is the architectural direction.

## Why Strategies Should Explain Themselves

An explainable strategy architecture allows the solver to become a teaching tool instead of only an answer generator.

For example, rather than only reporting:

```text
Set R3C7 = 5
```

an explainable solver could report:

```text
Hidden Single: 5 can only appear once in row 3, so R3C7 must be 5.
```

## Transitional Rule

Existing strategy code may remain in `Grid.pm` until tests exist around the
behavior. Do not split strategy code out merely for neatness unless the split
is protected by tests or is obviously behavior-preserving.
