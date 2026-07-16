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
