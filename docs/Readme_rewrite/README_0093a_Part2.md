## Output Formats

SudokuSolver separates puzzle solving from puzzle presentation through a flexible renderer architecture. The same solution can be displayed in multiple human-readable and machine-readable formats without affecting the underlying solver.

Supported output capabilities include:

- Traditional ASCII grid layouts
- Compact grid layouts
- Unicode box-drawing formats
- Candidate displays
- JSON export
- Single-line puzzle and solution formats
- Renderer-independent output events
- Optional colorized rendering

This separation allows new renderers and export formats to be added without modifying the solver itself.

Complete documentation of the available output formats is provided in the `docs/` directory.

---

## Solving Strategies

SudokuSolver is designed to solve puzzles using logical deduction rather than exhaustive search. Strategies are applied incrementally, beginning with elementary techniques and progressing toward increasingly sophisticated forms of reasoning.

The solver currently implements techniques from several major families.

### Singles

- Naked Single
- Hidden Single

### Subsets

- Naked Pair
- Hidden Pair
- Naked Triple
- Hidden Triple
- Naked Quad
- Hidden Quad

### Intersection Removal

- Pointing
- Claiming

### Fish

- X-Wing
- Swordfish
- Jellyfish

### Wings

- XY-Wing
- XYZ-Wing

### Chains and Coloring

- Remote Pairs
- Simple Coloring
- Multi-Coloring
- X-Chains
- XY-Chains
- Alternating Inference Chains (AIC)
- Grouped AIC
- Digit Forcing Chains
- Skyscraper
- Grouped L1 Wing

### Uniqueness

- Unique Rectangle Type 1

Each successful deduction records the strategy responsible, allowing the solver to produce detailed explanations, benchmark statistics, and difficulty information.

As new logical techniques are added, they integrate naturally into the existing strategy framework without affecting established solver behavior.

---

## The Definitive Corpus

One of SudokuSolver's primary goals is to provide a stable, reproducible corpus of Sudoku puzzles suitable for long-term research, benchmarking, and software development.

Rather than treating every published puzzle as unique, SudokuSolver recognizes that many puzzles differ only by symmetry transformations. Rotations, reflections, band and stack permutations, row and column permutations, digit relabelings, and transposition can all produce visually different puzzles that are logically equivalent.

The canonicalization system maps every member of an equivalence class to a single canonical representative. This produces a deterministic identity that remains stable regardless of the original orientation or labeling of the puzzle.

Every canonical puzzle receives:

- A permanent Canonical ID
- A compact fingerprint
- A complete solution
- Metadata describing the puzzle
- Provenance information
- A witness transform capable of reconstructing the original source puzzle

The result is a definitive corpus in which every logical puzzle appears exactly once.

### Deterministic by Design

Reproducibility is a central design goal.

Given the same source puzzles and the same canonicalization algorithm, SudokuSolver will always generate the same canonical corpus. Stable identifiers allow external tools, publications, and future releases to reference puzzles without ambiguity.

This deterministic approach enables reliable benchmarking, long-term research, and reproducible experimentation.

### Beyond Puzzle Collections

The definitive corpus is intended to serve multiple purposes.

For developers, it provides a stable benchmark suite.

For researchers, it provides canonical identities and reproducible metadata.

For collectors, it eliminates duplicate logical puzzles while preserving provenance.

For SudokuSolver itself, it provides the foundation for future query tools, metadata analysis, and reproducible puzzle generation.

Additional documentation describing the corpus architecture, canonicalization process, and JSON schema is available in:

- `docs/Corpus.md`
- `docs/Corpus_Schema.md`

These documents describe both the conceptual design of the corpus and the precise structure of the published data.
