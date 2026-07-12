# Unique Rectangle Type 3 — Algorithm Notes

1. Enumerate rectangles formed by two rows and two columns.
2. Reject solved cells and rectangles spanning anything other than two boxes.
3. Find two aligned floor cells containing exactly the same pair.
4. Require both roof cells to contain that pair.
5. Collect the union of candidates in the roofs other than the deadly pair.
6. Treat that union as one virtual subset cell.
7. In the shared roof unit, choose `extras - 1` other cells whose candidates
   are contained in, and collectively equal, the extra-candidate set.
8. Remove those extras from every other cell in the roof unit.

The implementation supports generalized Type 3 subsets rather than only a
fixed pair/triple example.
