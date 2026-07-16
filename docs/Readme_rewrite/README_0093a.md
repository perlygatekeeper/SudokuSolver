# SudokuSolver

*A modern Perl Sudoku solver featuring human-style logical solving, deterministic canonicalization, and a definitive reproducible puzzle corpus.*

---

## Introduction

SudokuSolver is an open-source command-line application for solving classic 9×9 Sudoku puzzles using the same logical techniques employed by experienced human solvers. Rather than relying on brute force or exhaustive search, it explains solutions through a progression of increasingly sophisticated deduction strategies, making it suitable both as a practical solving tool and as a platform for studying Sudoku logic.

Beyond solving individual puzzles, SudokuSolver provides a comprehensive toolkit for working with Sudoku collections. It can canonicalize puzzles under the full set of Sudoku-preserving symmetries, assign stable permanent identifiers, generate compact fingerprints, record reversible witness transforms, and build a deterministic master corpus containing canonical puzzles together with their solutions and metadata.

The project is designed for three complementary audiences:

- **Puzzle solvers** who want clear, human-readable explanations of how a puzzle can be solved.
- **Developers** who need stable command-line tools, machine-readable exports, and a well-structured codebase.
- **Researchers and collectors** who require reproducible canonical representations, permanent puzzle identities, and a definitive corpus suitable for analysis.

SudokuSolver is written in modern Perl and emphasizes correctness, determinism, reproducibility, and maintainability. Every major feature is supported by an extensive automated test suite, allowing the project to evolve while preserving consistent behavior.

---

## Terminology

### Puzzle

A standard 9×9 Sudoku grid containing a set of given clues. Unless otherwise stated, "puzzle" refers only to the starting grid and not its solution.

### Solution

The completed Sudoku grid satisfying all Sudoku constraints for a puzzle.

### Equivalence Class

The complete set of puzzles obtainable from one another through the allowed Sudoku-preserving symmetry transformations. Every puzzle within an equivalence class represents the same underlying logical puzzle and shares a common canonical representation.

### Canonicalization

The deterministic process of transforming every member of an equivalence class into a single, unique representative while recording sufficient information to reconstruct the original puzzle.

### Canonical Puzzle

The unique representative selected for an equivalence class by the project's canonicalization algorithm. The current implementation chooses the lexicographically smallest member of the class.

### Fingerprint

A compact, deterministic encoding of the clue locations in a canonical puzzle. Fingerprints provide concise identifiers that are convenient for indexing, searching, and comparing puzzles.

### Canonical ID

A stable, permanent identifier assigned to each canonical puzzle. Canonical IDs are intended to remain unchanged across future corpus releases, allowing external tools and publications to reference puzzles reliably.

### Witness Transform

The reversible sequence of symmetry operations that maps an original source puzzle to its canonical puzzle. Applying the inverse witness transform reconstructs the original puzzle exactly.

### Corpus

The definitive collection of canonical Sudoku puzzles together with their solutions, metadata, provenance, and reproducibility information maintained by this project.

---

## Features

SudokuSolver combines a human-style logical solver with a growing collection of developer and research tools.

### Human-style logical solving

- Solves puzzles using progressively more advanced logical deduction techniques.
- Produces step-by-step explanations suitable for learning and analysis.
- Avoids guessing or brute-force search during normal logical solving.
- Reports the strategies used and their contributions to the solution.

### Multiple output formats

- Traditional and compact grid layouts.
- Unicode and ASCII rendering.
- Machine-readable JSON export.
- Candidate export formats.
- One-line puzzle and solution formats.
- Renderer architecture designed for future extensions.

### Canonicalization and corpus tools

- Deterministic puzzle canonicalization.
- Stable canonical identifiers.
- Compact fingerprints.
- Recorded witness transforms.
- Reproducible corpus generation.
- Query interfaces for corpus exploration.

### Benchmarking and validation

- Integrated benchmark suites.
- Corpus validation tools.
- Comprehensive regression tests.
- Reproducible performance measurements.

### Modern project architecture

- Modular strategy framework.
- Extensive automated testing.
- Consistent command-line interface.
- Developer-oriented documentation.
- Designed for long-term maintainability.

---

## Installation

### Requirements

SudokuSolver requires:

- Perl 5.34 or newer
- Standard Perl modules listed by the project
- GNU Make

Clone the repository:

```bash
git clone https://github.com/perlygatekeeper/SudokuSolver.git
cd SudokuSolver
```

Verify the installation:

```bash
make syntax
make test
```

or run the complete validation suite:

```bash
make check
```

All tests should complete successfully before using or modifying the project.

---

## Quick Start

Solve a puzzle:

```bash
bin/sudoku.pl PUZZLE
```

where `PUZZLE` is an 81-character Sudoku string using digits for clues and `.` or `0` for empty cells.

Display available output formats:

```bash
bin/sudoku.pl --grid-formats
```

Select a specific renderer:

```bash
bin/sudoku.pl --grid-format=unicode
```

Generate machine-readable output:

```bash
bin/sudoku.pl --json PUZZLE
```

Display remaining candidates:

```bash
bin/sudoku.pl --dump-candidates PUZZLE
```

Additional examples, output formats, and corpus tools are described later in this document and in the documentation under `docs/`.
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
## Examples

SudokuSolver includes a growing collection of examples demonstrating common workflows, command-line usage, output formats, and developer features.

Representative examples include:

- Solving a puzzle from the command line
- Producing step-by-step logical explanations
- Selecting alternate grid renderers
- Exporting JSON and candidate data
- Running benchmark suites
- Working with the canonical corpus
- Querying corpus metadata
- Building reproducible datasets

The `examples/` directory is intended to serve both as a tutorial for new users and as a reference for experienced users exploring less common functionality.

---

## Documentation

Additional documentation is provided throughout the repository.

| Document | Description |
|----------|-------------|
| `Readme.md` | Project overview and quick start guide |
| `docs/Corpus.md` | Design and construction of the definitive corpus |
| `docs/Corpus_Schema.md` | Formal schema for published corpus records |
| `docs/Output_Formats.md` | Grid renderers and export formats |
| `docs/Developer/` | Internal architecture and implementation notes |
| `docs/Roadmap.txt` | Planned future development |
| `Release_Notes/` | Project release history |

The documentation is organized so that the README provides an overview while the remaining documents explore individual topics in greater depth.

---

## Roadmap

SudokuSolver continues to evolve in several complementary directions.

### Solver

- Additional advanced logical techniques
- Continued solver optimization
- Expanded difficulty analysis
- Improved explanation quality

### Corpus

- Additional metadata
- Expanded query capabilities
- Published corpus releases
- Long-term identifier stability

### Output

- Additional renderers
- Enhanced machine-readable exports
- Visualization improvements
- Additional interchange formats

### Developer Experience

- Expanded examples
- Additional API documentation
- Improved benchmarking tools
- Continued test coverage

The project emphasizes incremental improvement while preserving backward compatibility, deterministic behavior, and reproducible results.

---

## Project Philosophy

SudokuSolver is guided by four core principles.

### Human-Style Logic

Solutions should be understandable. Whenever practical, puzzles are solved using logical deduction rather than exhaustive search.

### Deterministic Results

Given identical inputs, the project should always produce identical outputs. Deterministic behavior is fundamental to reliable testing, benchmarking, and research.

### Reproducible Data

Published corpora, benchmark results, and exported metadata should be reproducible from authoritative source material using documented procedures.

### Stable Interfaces

Public command-line interfaces, published corpus formats, and permanent identifiers should evolve carefully so that external users can depend upon them over the long term.

---

## License

SudokuSolver is open-source software. See the repository license for licensing terms and conditions.

---

## Acknowledgements

SudokuSolver builds upon decades of published Sudoku research and the contributions of the wider Sudoku community. The project also benefits from publicly available benchmark collections and the continued efforts of puzzle authors, researchers, and enthusiasts who have advanced the understanding of logical Sudoku solving.
