# Unique Rectangle Type 4 — Algorithm Notes

1. Enumerate two-box rectangles.
2. Find two aligned floor cells containing exactly the same pair.
3. Require both roof cells to contain the pair and at least one extra.
4. Inspect the row or column shared by the roof cells.
5. If one deadly-pair candidate occurs only in those two roof cells, it is a
   strong link.
6. Remove the other deadly-pair candidate from both roof cells.

Both roof cells must contain extras so Type 1 retains its simpler case.
