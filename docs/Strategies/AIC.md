# Alternating Inference Chains (AIC)

## Human-solving description

An Alternating Inference Chain is a sequence of candidate nodes joined by
alternating strong and weak links. A strong link says that at least one of its
two candidates must be true. A weak link says that both candidates cannot be
true.

When a chain begins and ends with strong links on the same candidate digit, the
two endpoints cannot both be false. Any outside candidate that sees both
endpoints can therefore be eliminated.

## Solver behavior

The strategy uses candidate nodes written as `RrCc(d)`. Strong links come from:

* conjugate candidate pairs in a row, column, or box; and
* the two candidates in a bivalue cell.

Weak links come from candidates that cannot both be true because they share a
cell or because the same digit shares a row, column, or box.

The search is bounded to nine candidate nodes. Specialized strategies run
before AIC so Skyscrapers, X-Chains, XY-Chains, and similar patterns retain
their more specific explanations.
