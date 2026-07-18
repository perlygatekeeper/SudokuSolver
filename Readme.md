# SudokuSolver

*A modern Perl toolkit for human-style Sudoku solving, deterministic puzzle
canonicalization, and reproducible Sudoku research.*

SudokuSolver is more than a Sudoku solver. It is a command-line toolkit for
solving puzzles, explaining logical deductions, assigning stable puzzle
identities, building reproducible canonical corpora, and supporting long-term
Sudoku analysis.

Unlike solvers that rely primarily on search or backtracking, SudokuSolver
emphasizes human-style logical deduction. Every successful deduction is
attributed to the strategy that produced it, allowing the program to explain
how a puzzle was solved rather than merely presenting the finished grid.

Version 1.0.0 completed the project's original solver goal: solving the full
canonical collection of minimal 17-clue Sudoku puzzles without unrestricted
recursive backtracking.

```text
Puzzles processed : 49,158
Solved            : 49,158
Stalled           : 0
Contradictions    : 0
```

Version 1.1.0 expanded the presentation layer with text, document, image, and
machine-readable output formats while preserving the same solver behavior.

Version 1.2.0 adds the canonical corpus and reproducible generation platform:
stable corpus IDs, coordinate fingerprints, seeded symmetry transforms,
controlled clue reveals, difficulty-targeted generation, and replayable
provenance artifacts.

Version 1.2.1 keeps that corpus functionality while replacing the large
checked-in source corpus with the compressed master corpus for a much smaller
clone.

These four ideas define the project:

- **Solve** puzzles using progressively more sophisticated human-style logic.
- **Explain** every deduction through reproducible strategy reporting.
- **Canonicalize** logically equivalent puzzles into stable identities.
- **Research** using deterministic corpora, permanent IDs, and reproducible data.

## Features

### Human-Style Logical Solving

- Solves puzzles using progressively more advanced logical deduction.
- Produces step-by-step explanations suitable for learning and analysis.
- Avoids unrestricted brute-force search during normal logical solving.
- Records successful deductions as structured `Sudoku::Deduction` objects.
- Reports terminal status, contradictions, difficulty, and strategy statistics.

### Flexible Output System

- Traditional, compact, worksheet, candidate, and Unicode grid layouts.
- Markdown, HTML, SVG, PNG, and PDF grid rendering.
- JSON, CSV, and TSV solve-result exports.
- Candidate-state exports for fixtures, diffs, and downstream tools.
- One-line puzzle, grid, and solution formats.
- Optional terminal color themes for human-readable output.
- Renderer architecture separated from solver behavior.

### Canonicalization and Corpus Management

- Deterministic puzzle canonicalization under Sudoku-preserving symmetries.
- Stable `17C-NNNNNN` canonical IDs.
- Compact 42-character canonical fingerprints for 17-clue puzzles.
- Reversible witness transforms.
- Deterministic staging indexes and master-corpus build tools.
- Versioned JSONL master-corpus schema.

### Benchmarking and Validation

- Integrated benchmark targets for development and release checks.
- Full 49,158-puzzle canonical corpus capability benchmark.
- Corpus validation and canonicalization audit tools.
- Comprehensive regression testing.
- Deterministic build steps for canonical IDs, solutions, and master records.

### Modern Architecture

- Modular strategy framework.
- Stable command-line interface.
- Structured solver contracts and renderer contracts.
- Extensive developer documentation.
- Long-term maintainability as an explicit project goal.

## Project Philosophy

> Prefer explainable logical inference over unrestricted search.

SudokuSolver is guided by four principles.

### Human-Style Logic

Solutions should be understandable. Whenever practical, puzzles are solved
through logical deduction rather than exhaustive search.

The most advanced fallback is bounded hypothetical inference. It makes one
candidate assumption at a time, performs limited deterministic propagation, and
accepts only a contradiction or a conclusion shared by both branches. It does
not use unrestricted recursive search as proof of an ordinary deduction.

### Deterministic Behavior

Identical inputs should produce identical outputs. Determinism makes reliable
testing, benchmarking, and long-term research possible.

### Reproducible Data

Published corpora, benchmark results, and exported metadata should be
reproducible from authoritative source material using documented procedures.

### Stable Interfaces

Command-line interfaces, renderer contracts, corpus formats, and canonical IDs
should evolve carefully so external tools can depend on them over time.

## Installation

### Requirements

- Perl 5.34 or newer
- `cpanm` or another CPAN client
- GNU Make or a compatible `make`

Perl dependencies are declared in `cpanfile`.

Clone the repository and install dependencies:

```sh
git clone https://github.com/perlygatekeeper/SudokuSolver.git
cd SudokuSolver
cpanm --installdeps .
```

Verify the installation:

```sh
make syntax
make test
```

or run the complete validation suite:

```sh
make check
```

To use a specific Perl interpreter:

```sh
make PERL=/path/to/perl check
```

## Quick Start

Solve a puzzle file:

```sh
perl -Ilib bin/sudoku.pl --file Puzzles/Puzzle3.txt
```

Solve an 81-character puzzle string:

```sh
perl -Ilib bin/sudoku.pl --string \
003020600900305001001806400008102900700000008006708200002609500800203009005010300
```

Solve a puzzle from a one-line puzzle file:

```sh
perl -Ilib bin/sudoku.pl \
    --file Puzzles/Puzzle_Dispatch_20191209.txt
```

Ask for an explanation-oriented solve:

```sh
perl -Ilib bin/sudoku.pl --output explain --file Puzzles/Puzzle3.txt
```

Display command-line help or the installed version:

```sh
perl -Ilib bin/sudoku.pl --help
perl -Ilib bin/sudoku.pl --version
```

Generate a reproducible puzzle from the canonical corpus:

```sh
perl -Ilib bin/generate-puzzle.pl --seed 123 --clues 30
```

Generate a worksheet-style puzzle without showing candidates:

```sh
perl -Ilib bin/generate-puzzle.pl \
    --seed 123 \
    --clues 30 \
    --format worksheet
```

Generate a difficulty-targeted replay artifact:

```sh
perl -Ilib bin/generate-puzzle.pl \
    --seed 123 \
    --clues 30 \
    --difficulty Medium \
    --format json \
    --output-file generated-puzzle.json
```

Difficulty-targeted generation starts from corpus records already at or above
the requested difficulty floor, then still solves and rates the generated
puzzle before accepting it.

Add `--debug` to print each difficulty-targeted attempt to standard error:

```sh
perl -Ilib bin/generate-puzzle.pl \
    --seed 123 \
    --clues 30 \
    --difficulty Medium \
    --debug
```

## Output Formats

SudokuSolver separates solving from presentation. The solver produces stable
deductions and terminal status; independent renderers decide how final grids,
candidate states, and solve results are displayed.

Discover available formats at runtime:

```sh
perl -Ilib bin/sudoku.pl --list-grid-formats
perl -Ilib bin/sudoku.pl --list-character-sets
perl -Ilib bin/sudoku.pl --list-result-formats
perl -Ilib bin/sudoku.pl --list-color-themes
```

Render a compact final grid:

```sh
perl -Ilib bin/sudoku.pl \
    --output quiet \
    --grid-format compact \
    --file Puzzles/Puzzle3.txt
```

Render a Unicode pretty grid:

```sh
perl -Ilib bin/sudoku.pl \
    --output quiet \
    --grid-format pretty \
    --character-set UNICODE_LIGHT \
    --file Puzzles/Puzzle3.txt
```

Render a worksheet grid with candidate-sized cells but blank unsolved cells:

```sh
perl -Ilib bin/sudoku.pl \
    --output quiet \
    --grid-format worksheet \
    --character-set UNICODE_LIGHT \
    --file Puzzles/Puzzle3.txt
```

`UNICODE_MIXED` combines heavy box boundaries with light individual-cell
separators for terminal display.

### Document and Image Grids

Final grids can be rendered as Markdown, standalone HTML, SVG, PNG, or PDF.
PNG and PDF are binary formats and should be written with `--output-file`.

```sh
perl -Ilib bin/sudoku.pl --output quiet --grid-format markdown --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format html \
    --output-file puzzle.html --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format svg \
    --output-file puzzle.svg --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format png \
    --output-file puzzle.png --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format pdf \
    --output-file puzzle.pdf --file Puzzles/Puzzle3.txt
```

### One-Line and Candidate Exports

The renderer can emit puzzle, current-grid, and solution lines for compact
interchange:

```sh
perl -Ilib bin/sudoku.pl --output quiet --grid-format puzzle-line --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format grid-line --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --output quiet --grid-format solution-line --file Puzzles/Puzzle3.txt
```

It can also export candidate state for fixtures and downstream tools:

```sh
perl -Ilib bin/sudoku.pl --output quiet --grid-format candidates --file puzzle.sdk
perl -Ilib bin/sudoku.pl --output quiet --grid-format candidate-list --file puzzle.sdk
perl -Ilib bin/sudoku.pl --output quiet --grid-format candidate-line --file puzzle.sdk
perl -Ilib bin/sudoku.pl --output quiet --grid-format candidate-json --file puzzle.sdk
```

### Structured Results

Use `--result-format` to export a solve result instead of human narration:

```sh
perl -Ilib bin/sudoku.pl --result-format json --file puzzle.sdk
perl -Ilib bin/sudoku.pl --result-format csv --output-file result.csv --file puzzle.sdk
perl -Ilib bin/sudoku.pl --result-format tsv --output-file result.tsv --file puzzle.sdk
```

Structured result exports include status, puzzle, current grid, solution when
solved, deduction count, difficulty rating, strategy statistics, and
contradiction details when present.

### Terminal Color

Human-readable output supports optional ANSI styling:

```sh
perl -Ilib bin/sudoku.pl --color auto --color-theme subtle --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --color always --color-theme bright --file Puzzles/Puzzle3.txt
perl -Ilib bin/sudoku.pl --color never --file Puzzles/Puzzle3.txt
```

Color activation and appearance are independent. The included themes are
`subtle`, `bright`, and `greyscale`. Machine-readable JSON, CSV, TSV, and
interchange-oriented line formats remain plain.

## Solving Strategies

Strategies are applied incrementally, beginning with elementary techniques and
progressing toward increasingly sophisticated forms of reasoning.

### Singles and Intersections

- Naked Singles
- Hidden Singles
- Pointing / Claiming

### Subsets

- Naked Pairs, Triples, and Quads
- Hidden Pairs, Triples, and Quads

### Fish

- X-Wing
- Swordfish
- Jellyfish

### Wings and Uniqueness

- XY-Wing
- XYZ-Wing
- WXYZ-Wing
- Unique Rectangle Types 1 through 4

### Patterns, Coloring, and Chains

- Remote Pairs
- Skyscraper
- Two-String Kite
- Empty Rectangle
- Simple Coloring
- Multi-Coloring
- X-Chains
- XY-Chains
- Alternating Inference Chains
- Grouped L1-Wing
- Grouped Alternating Inference Chains
- Digit Forcing Chains

Each successful deduction records the strategy responsible, allowing the solver
to produce explanations, benchmark statistics, and difficulty information.

## The Definitive Corpus

One of SudokuSolver's major goals is to provide a stable, reproducible corpus
of Sudoku puzzles suitable for research, benchmarking, and software
development.

The 17-clue source material is credited to the McGuire/Royle minimal-clue
Sudoku research line: Gordon Royle's catalogue of known 17-clue Sudoku puzzles,
and Gary McGuire, Bastian Tugemann, and Gilles Civario's proof that no
uniquely-solvable standard Sudoku puzzle exists with 16 clues. See
[Royle, *Minimum Sudoku*](https://web.archive.org/web/20160113065147/http://staffhome.ecm.uwa.edu.au/~00013890/sudokumin.php)
and McGuire, Tugemann, and Civario,
[*There is no 16-Clue Sudoku: Solving the Sudoku Minimum Number of Clues Problem via Hitting Set Enumeration*](https://arxiv.org/abs/1201.0749).
The 49,158-puzzle source file used for the current corpus was obtained as
[17puz49158.zip](https://drive.google.com/file/d/1StS_Sm_Eh9ZJTapOsrRJccM6UP6PmQ3B/view).

Many published puzzles differ only by Sudoku-preserving symmetry transforms:
digit relabelings, row and column permutations, band and stack permutations,
and related spatial transforms. SudokuSolver's canonicalization system maps
each member of an equivalence class to a single canonical representative and
records the witness transform needed to reconstruct the source puzzle.

Every canonical master-corpus record is designed to include:

- a stable canonical ID;
- a compact canonical fingerprint;
- the canonical 81-character puzzle;
- the complete solution;
- schema and provenance metadata; and
- replayable transform information from earlier build stages.

The authoritative master artifact is planned and documented as JSONL. The
supporting TSV files generated during canonicalization are build artifacts, not
the public corpus format.

Useful corpus and canonicalization targets include:

```sh
make corpus-audit
make canonical-benchmark
make canonical-index
make canonical-identities
make canonical-solutions
make master-corpus
make corpus-cache
```

`make corpus-cache` builds a local SQLite lookup cache from the master corpus.
The cache is ignored by git; the compressed JSONL corpus remains the
authoritative checked-in artifact.

Additional design details are documented in:

- `docs/Developer/Canonical_Corpus_and_Generation_Architecture.md`
- `docs/Developer/Corpus_Difficulty_Distribution.md`
- `docs/Developer/Puzzle_Canonicalization.md`
- `docs/Developer/Sudoku_Symmetries.md`
- `docs/Developer/Master_Corpus_JSONL_Schema.md`

## Testing

Run syntax checks and the full automated test suite:

```sh
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

## Repository Layout

```text
bin/                 command-line tools
lib/                 solver, grid, strategy, renderer, and support modules
t/                   automated test suite
Puzzles/             examples and benchmark puzzle collections
docs/                user, strategy, algorithm, release, and developer docs
```

## Documentation

The README provides a project overview and quick start. The deeper documents
describe individual topics in more detail.

| Document | Purpose |
|----------|---------|
| `Readme.md` | Project overview and quick start |
| `docs/Release_notes_v1.0.0.txt` | v1.0 solver-completion release notes |
| `docs/Release_notes_v1.1.0.txt` | v1.1 output-system release notes |
| `docs/Release_notes_v1.2.0.txt` | v1.2 corpus-generation release notes |
| `docs/Release_notes_v1.2.1.txt` | v1.2.1 reduced-distribution release notes |
| `docs/Roadmap.txt` | Current and planned development |
| `docs/Strategy_Development_Guide.txt` | Guide for adding solver strategies |
| `docs/Developer/Architecture.md` | Internal architecture notes |
| `docs/Developer/Benchmark.md` | Benchmark design and operation |
| `docs/Developer/Current_Status_and_Subprojects.md` | Current project status |
| `docs/Developer/Output_Architecture.md` | Renderer architecture |
| `docs/Developer/Output_Contracts.md` | Output compatibility contracts |
| `docs/Developer/Output_Formats.md` | Grid and result formats |
| `docs/Developer/Color_Themes.md` | Terminal color themes |

## Roadmap

SudokuSolver continues to evolve in several complementary directions.

### Solver

- Performance profiling and optimization.
- Difficulty calibration improvements.
- Clearer explanations and comparative solve reports.
- New strategies only when they provide clearer proofs, better performance, or
  useful analysis value.

### Corpus

- Compressed master-corpus distribution.
- Aggregate full-corpus benchmark reporting.
- Additional corpus metadata views when they support research or release QA.
- Long-term compatibility checks for generated-puzzle replay artifacts.

### Output

- Additional renderers and replay formats.
- Richer machine-readable exports.
- Benchmark output through common renderer contracts.
- Candidate-state interchange improvements.

### Developer Experience

- Continuous integration.
- Release helpers and packaging checks.
- More reusable fixtures and integration-test helpers.
- Documentation consistency checks.

The project emphasizes incremental improvement while preserving deterministic
behavior, stable interfaces, and reproducible results.

## Release Status

Version 1.0.0 marks completion of the original solver vision:

- the full canonical 17-clue corpus is solved;
- all deductions remain explainable and auditable;
- contradictions are detected rather than concealed;
- output is separated from solving through renderer interfaces; and
- the project has broad automated regression coverage.

Version 1.1.0 completed the presentation, export, documentation, and
command-line usability track. Solver behavior and solving techniques are
unchanged from v1.0.0.

Version 1.2.0 completes canonical corpus identity and reproducible generation:
queryable permanent corpus records, seeded symmetry variants, controlled clue
reveals, difficulty-targeted generation, and replayable provenance.

Version 1.2.1 completes the reduced-distribution pass by keeping the compressed
master corpus in the repository while preserving the full-history archive
outside the working clone.

Post-1.2.1 development is focused on aggregate benchmark reporting, packaging
and release automation, continuous integration, and future user interfaces.

## License

SudokuSolver is open-source software. See the repository license for licensing
terms and conditions.

## Acknowledgements

SudokuSolver builds upon decades of published Sudoku research and the wider
Sudoku community's work on logical solving techniques, benchmark collections,
and reproducible puzzle analysis. The project's minimal-clue corpus work gives
particular credit to Gordon Royle's 17-clue Sudoku catalogue and to Gary
McGuire, Bastian Tugemann, and Gilles Civario's minimum-clue proof.
