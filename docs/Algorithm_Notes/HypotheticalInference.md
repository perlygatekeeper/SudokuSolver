# Hypothetical Inference Algorithm Notes

## Purpose

The hypothetical inference engine supplies controlled branch evaluation for
future Digit, Cell, and Unit Forcing Chains.

## Grid cloning

The branch begins with a new `Grid`. Values, clue flags, solved count, and all
candidate arrays are copied cell by cell. Reloading only the 81-character puzzle
string would be insufficient because it would lose the exact candidate state.

## Assumptions

An ON assumption temporarily sets one available candidate as the cell value.
An OFF assumption temporarily removes one available candidate.

An assumption immediately contradicts the branch when it conflicts with a
solved value or attempts to set a candidate that is already absent.

## Propagation

After the single assumption, `Solver::propagate()` repeatedly calls the normal
one-step solver. Every successful deduction restarts strategy selection from
the beginning, exactly as in an ordinary solve.

No nested assumption is permitted. The engine performs deterministic
propagation only.

## Results

The branch returns:

- terminal status;
- cloned final grid;
- consequence deductions;
- placements and eliminations;
- ordered history;
- structured contradiction when present;
- number of propagated steps.

Future forcing-chain strategies will compare two or more such branch results to
find contradictions or conclusions common to every branch.
