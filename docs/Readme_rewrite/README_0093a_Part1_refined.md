# SudokuSolver

*A modern Perl toolkit for human-style Sudoku solving, deterministic puzzle canonicalization, and reproducible Sudoku research.*

SudokuSolver is more than a Sudoku solver.

It is a complete toolkit for solving puzzles, explaining logical deductions, assigning permanent puzzle identities, building reproducible canonical corpora, and supporting long-term Sudoku research.

Whether your goal is to solve a single puzzle, benchmark a solving algorithm, study advanced solving techniques, or construct a definitive collection of canonical puzzles, SudokuSolver provides a consistent and deterministic foundation.

Unlike solvers that rely primarily on search or backtracking, SudokuSolver emphasizes human-style logical deduction. Every successful deduction is attributed to the strategy that produced it, allowing the program to explain *how* a puzzle was solved rather than merely presenting the finished grid.

Beyond solving, the project introduces a deterministic canonicalization system capable of recognizing every member of a Sudoku equivalence class, transforming each puzzle into a unique canonical representative, recording the reversible witness transform, assigning a permanent canonical identifier, and generating a reproducible master corpus suitable for benchmarking, analysis, and publication.

These four ideas define the project:

- **Solve** puzzles using progressively more sophisticated human-style logic.
- **Explain** every deduction through reproducible strategy reporting.
- **Canonicalize** logically equivalent puzzles into permanent identities.
- **Research** using deterministic corpora, stable identifiers, and reproducible data.

SudokuSolver is written in modern Perl and is designed around four principles:

- Correctness
- Determinism
- Reproducibility
- Long-term maintainability

Every significant feature is protected by an extensive automated test suite so that the project can continue to evolve without sacrificing stable behavior.

---

# Features

SudokuSolver combines a human-style logical solver with a growing collection of developer and research tools.

### Human-style logical solving

- Solves puzzles using progressively more advanced logical deduction.
- Produces step-by-step explanations suitable for learning and analysis.
- Avoids brute-force search during normal logical solving.
- Records every successful deduction together with the strategy that produced it.

### Flexible output system

- Traditional and compact grid layouts
- Unicode and ASCII renderers
- Machine-readable JSON
- Candidate exports
- One-line puzzle and solution formats
- Renderer architecture designed for future expansion

### Canonicalization and corpus management

- Deterministic puzzle canonicalization
- Stable Canonical IDs
- Compact fingerprints
- Witness transforms
- Reproducible corpus generation
- Corpus query interfaces

### Benchmarking and validation

- Integrated benchmark suites
- Corpus validation tools
- Comprehensive regression testing
- Deterministic performance measurements

### Modern architecture

- Modular strategy framework
- Stable command-line interface
- Extensive developer documentation
- Long-term maintainability

---

# Project Philosophy

SudokuSolver is guided by four principles.

## Human-style logic

Solutions should be understandable.

Whenever practical, puzzles are solved through logical deduction rather than exhaustive search.

## Deterministic behavior

Identical inputs should always produce identical outputs.

Determinism makes reliable testing, benchmarking, and long-term research possible.

## Reproducible data

Published corpora, benchmark results, and exported metadata should always be reproducible from documented source material.

## Stable interfaces

Command-line interfaces, published corpus formats, renderer contracts, and Canonical IDs are intended to evolve carefully so external tools can depend upon them over the long term.

---

# Installation

## Requirements

SudokuSolver requires:

- Perl 5.34 or newer
- GNU Make
- The standard Perl modules required by the project

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

# Quick Start

Solve a puzzle:

```bash
bin/sudoku.pl PUZZLE
```

where `PUZZLE` is an 81-character Sudoku string using digits for clues and `.` or `0` for empty cells.

Display the available grid renderers:

```bash
bin/sudoku.pl --grid-formats
```

Select a renderer:

```bash
bin/sudoku.pl --grid-format=unicode
```

Generate machine-readable JSON:

```bash
bin/sudoku.pl --json PUZZLE
```

Display remaining candidates:

```bash
bin/sudoku.pl --dump-candidates PUZZLE
```

More examples, renderer documentation, and corpus tools are provided throughout the repository.

---

# Documentation

The README provides an overview of the project.

Detailed documentation is available throughout the repository.

| Document | Purpose |
|----------|---------|
| `README.md` | Project overview and quick start |
| `docs/Corpus.md` | Definitive corpus architecture |
| `docs/Corpus_Schema.md` | Published corpus schema |
| `docs/Output_Formats.md` | Grid renderers and export formats |
| `docs/Developer/` | Internal architecture and developer notes |
| `docs/Roadmap.txt` | Planned future development |
| `Release_Notes/` | Project release history |

The remaining documents expand upon individual topics without overwhelming the project's front page.

---

# Output Formats

SudokuSolver separates solving from presentation.

The logical solver produces a stable sequence of deduction events while independent renderers determine how those events are displayed.

Current output capabilities include:

- Traditional ASCII grids
- Compact grids
- Unicode box-drawing grids
- Candidate displays
- JSON export
- One-line puzzle and solution formats
- Renderer-independent event streams
- Optional colorized rendering

Because solving and rendering are independent, new output formats can be added without modifying the solving engine itself.
