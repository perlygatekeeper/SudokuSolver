# SudokuSolver

SudokuSolver is a modern Perl Sudoku solver built around explainable logical
inference. It solves puzzles by applying named Sudoku strategies, records each
deduction as structured data, and can present the result for people, tests, or
other programs.

Version 1.0.0 completes the project's original goal: solving the entire
canonical collection of 49,158 minimal 17-clue Sudoku puzzles without
unrestricted recursive backtracking.

```text
Puzzles processed : 49,158
Solved            : 49,158
Stalled           : 0
Contradictions    : 0
```

## Project Philosophy

> Prefer explainable logical inference over unrestricted search.

SudokuSolver is intended to be useful as both a capable solver and a teaching
and analysis tool. Strategies are isolated, tested, and expected to explain why
each placement or candidate elimination is valid.

The most advanced fallback is bounded hypothetical inference. It makes one
candidate assumption at a time, performs limited deterministic propagation,
and accepts only a contradiction or a conclusion shared by both branches. It
does not use an unrestricted recursive search for a completed grid.

## Features

- Logic-first solving with structured `Sudoku::Deduction` objects
- Human-readable normal, explain, trace, and debug output modes
- Step-by-step solving and hint support
- Contradiction detection and terminal solve status
- Versioned difficulty ratings and detailed strategy statistics
- Stable benchmark support for individual files and the canonical corpus
- Pretty, compact, candidate, and machine-readable grid renderers
- ASCII and Unicode grid character sets
- Versioned JSON solve results and candidate-state exports
- Output redirection to files
- Renderer event objects and an ordered event log

## Supported Strategies

SudokuSolver currently includes:

- Singles: Naked Singles and Hidden Singles
- Intersections: Pointing / Claiming
- Subsets: Naked and Hidden Pairs, Triples, and Quads
- Fish: X-Wing, Swordfish, and Jellyfish
- Wings: XY-Wing, XYZ-Wing, and WXYZ-Wing
- Uniqueness: Unique Rectangle Types 1 through 4
- Single-digit patterns: Remote Pairs, Skyscraper, Two-String Kite, and Empty Rectangle
- Coloring and chains: Simple Coloring, Multi-Coloring, X-Chains, and XY-Chains
- Advanced inference: AIC, Grouped L1-Wing, Grouped AIC, and Digit Forcing Chains

Several strategy families share reusable infrastructure, including fish
detection, strong-link discovery, grouped inference nodes, and bounded
hypothetical propagation.

## Requirements

- Perl 5.34 or newer
- `cpanm` or another CPAN client
- GNU Make or a compatible `make`

Perl dependencies are declared in `cpanfile`.

## Installation

```bash
git clone <repository-url> SudokuSolver
cd SudokuSolver
cpanm --installdeps .
make check
```

To use a specific Perl interpreter:

```bash
make PERL=/path/to/perl check
```

## Quick Start

Solve a puzzle file:

```bash
perl bin/sudoku.pl --file Puzzles/Puzzle3.txt
```

Solve the seventh puzzle in a multi-puzzle file:

```bash
perl bin/sudoku.pl \
    --file Puzzles/sudoku17-first50.txt \
    --puzzle 7
```

Solve an 81-character puzzle string:

```bash
perl bin/sudoku.pl --string \
003020600900305001001806400008102900700000008006708200002609500800203009005010300
```

Ask for an explanation-oriented solve:

```bash
perl bin/sudoku.pl --output explain --file Puzzles/Puzzle3.txt
```

Display command-line help or the installed version:

```bash
perl bin/sudoku.pl --help
perl bin/sudoku.pl --version
```

## Output Formats

Discover the available formats at runtime:

```bash
perl bin/sudoku.pl --list-grid-formats
perl bin/sudoku.pl --list-character-sets
perl bin/sudoku.pl --list-result-formats
```

Render only a compact final grid:

```bash
perl bin/sudoku.pl \
    --output quiet \
    --grid-format compact \
    --file Puzzles/Puzzle3.txt
```

Render a Unicode pretty grid:

```bash
perl bin/sudoku.pl \
    --output quiet \
    --grid-format pretty \
    --character-set UNICODE_LIGHT \
    --file Puzzles/Puzzle3.txt
```

Export the complete 81-cell candidate state:

```bash
perl bin/sudoku.pl --output quiet --grid-format candidate-line --file puzzle.sdk
perl bin/sudoku.pl --output quiet --grid-format candidate-json --file puzzle.sdk
```

Export a structured solve result:

```bash
perl bin/sudoku.pl --result-format json --file puzzle.sdk
```

Write any selected output to a file:

```bash
perl bin/sudoku.pl --output-file result.txt --file puzzle.sdk
```

The renderer architecture and format contracts are documented under
`docs/Developer/`.

## Terminal Color

Human-readable output supports optional ANSI styling:

```bash
perl bin/sudoku.pl --color auto --color-theme subtle --file Puzzles/Puzzle3.txt
perl bin/sudoku.pl --color always --color-theme bright --file Puzzles/Puzzle3.txt
perl bin/sudoku.pl --color never --file Puzzles/Puzzle3.txt
```

Color activation and appearance are independent. The available themes are
`subtle`, `bright`, and `greyscale`; discover them with
`--list-color-themes`. Machine-readable JSON, CSV, and TSV output is never
colored.

## Testing

Run the complete syntax and test suite:

```bash
make check
```

The three-digit test numbering groups tests by responsibility:

```text
000-099  loading, cells, and grids
100-199  solver engine and deduction infrastructure
200-599  solving strategies
600-699  user-facing solver features
700-799  rendering and output
800-899  benchmarking and difficulty
900-999  regression coverage
```

## Benchmarking

Run the standard first-1,000 regression benchmark:

```bash
make benchmark
```

Other useful targets include:

```bash
make benchmark-first50
make benchmark-first100
make benchmark-first1000
make benchmark-all-1000
make benchmark-final4
```

The first 1,000 canonical puzzles remain a convenient development regression
suite. The complete 49,158-puzzle canonical corpus is the authoritative
capability benchmark for version 1.0.0 and later development.

Benchmark reports and supporting files are stored under `Puzzles/Benchmarks/`
and `docs/`.

## Repository Layout

```text
bin/                 command-line program
lib/                 solver, grid, strategy, renderer, and support modules
t/                   automated test suite
Puzzles/             examples and benchmark puzzle collections
docs/                user, strategy, algorithm, and developer documentation
```

Useful developer documents include:

- `docs/Developer/Architecture.md`
- `docs/Developer/Benchmark.md`
- `docs/Developer/Output_Architecture.md`
- `docs/Developer/Output_Contracts.md`
- `docs/Developer/Output_Formats.md`
- `docs/Developer/Current_Status_and_Subprojects.md`
- `docs/Strategy_Development_Guide.txt`
- `docs/Roadmap.txt`

## Version 1.0.0

Version 1.0.0 marks completion of the original solver vision:

- the full canonical 17-clue corpus is solved;
- all deductions remain explainable and auditable;
- contradictions are detected rather than concealed;
- output is separated from solving through renderer interfaces; and
- the project has a broad automated regression suite.

See `Release_notes_v1.0.0.txt` for the release summary and
`docs/Roadmap.txt` for post-1.0 development priorities.

### Document and image exports

Final grids can also be rendered as Markdown, standalone HTML, SVG, PNG, or
PDF. Binary PNG and PDF output require `--output-file`.

```sh
bin/sudoku.pl --output quiet --grid-format markdown --file Puzzles/Puzzle3.txt
bin/sudoku.pl --output quiet --grid-format html --output-file puzzle.html --file Puzzles/Puzzle3.txt
bin/sudoku.pl --output quiet --grid-format svg --output-file puzzle.svg --file Puzzles/Puzzle3.txt
bin/sudoku.pl --output quiet --grid-format png --output-file puzzle.png --file Puzzles/Puzzle3.txt
bin/sudoku.pl --output quiet --grid-format pdf --output-file puzzle.pdf --file Puzzles/Puzzle3.txt
```

For terminal grids, `--character-set UNICODE_MIXED` combines heavy box
boundaries with light individual-cell separators.
