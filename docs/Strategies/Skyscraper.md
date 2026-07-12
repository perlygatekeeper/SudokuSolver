# Skyscraper

Skyscraper is a single-candidate chain pattern built from two strong links in
parallel rows or columns.

For a row-based Skyscraper, a candidate appears exactly twice in each of two
rows. One endpoint from each row lies in the same column; these are the
"floor" cells. The other endpoints are the "roofs."

Because each row contains a strong link, at least one roof must contain the
candidate. Any other cell that sees both roofs therefore cannot contain that
candidate. The column-based form is the transpose of the same pattern.

`Sudoku::Strategy::Skyscraper` is discovery-only. It returns structured
`Sudoku::Deduction` objects, records all four pattern cells, and does not mutate
the grid directly.
