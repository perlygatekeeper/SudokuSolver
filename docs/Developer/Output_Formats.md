# SudokuSolver Output Formats

SudokuSolver produces several kinds of textual output. These fall into four broad categories:

1. Grid representations
2. Solver narration
3. Final result summaries
4. Benchmark and diagnostic reports

Grid representation and solver narration are independent concepts. A grid may
be rendered in compact, pretty, worksheet, or candidate form while the solver
uses quiet, normal, puzzle, explain, trace, or debug narration.

## Grid Representations

## Grid Format Discovery

The text renderer provides a stable, discoverable entry point for named grid
formats:

```perl
my @formats = $renderer->available_grid_formats;
my $default = $renderer->default_grid_format;
my $known   = $renderer->supports_grid_format('compact');

my $text = $renderer->render_grid(
    $grid,
    format => 'pretty',
);
```

The currently available formats are, in discovery order:

```text
pretty
compact
markdown
html
svg
png
pdf
puzzle-line
grid-line
solution-line
worksheet
candidates
candidate-list
candidate-line
candidate-json
```

When `format` is omitted, `render_grid` uses `pretty`. This renderer default does
not by itself change the command-line program's existing output behavior.

Format-specific options are forwarded to the selected renderer. For example:

```perl
my $text = $renderer->render_grid(
    $grid,
    format               => 'compact',
    empty_cell_character => '_',
);
```



### Command-Line Discovery and Selection

The command-line program exposes the renderer registry without changing its
legacy default output:

```bash
sudoku.pl --list-grid-formats
sudoku.pl --list-character-sets
```

A final grid may be selected explicitly:

```bash
sudoku.pl --output quiet --grid-format compact --file puzzle.sdk
sudoku.pl --output quiet --grid-format pretty --character-set UNICODE_LIGHT --file puzzle.sdk
sudoku.pl --output quiet --grid-format worksheet --character-set UNICODE_LIGHT --file puzzle.sdk
sudoku.pl --output quiet --grid-format candidates --character-set UNICODE_DOUBLE --file puzzle.sdk
```

`--grid-format` is opt-in. If it is omitted, the existing command-line output
remains unchanged. Supplying `--character-set` by itself renders the default
`pretty` grid. Character-set names are case-insensitive and may use hyphens in
place of underscores.


### Candidate JSON

**Status:** Implemented as `Sudoku::Render::Text::candidate_json`

The candidate-JSON format preserves the original puzzle, current solved-cell
state, and every remaining candidate in a versioned machine-readable document.
The `candidates` array always contains exactly 81 strings in row-major order.
Solved cells contain their value, unsolved cells contain their remaining
candidates in ascending order, and a contradictory cell is represented by `-`.

```json
{
   "candidates" : [ "5", "3", "124", "26" ],
   "current_grid" : "530070000...",
   "format" : "SudokuSolver candidate-state",
   "puzzle" : "530070000...",
   "version" : 1
}
```

Command-line example:

```bash
sudoku.pl --output quiet --grid-format candidate-json --file puzzle.sdk
```

The JSON keys are emitted in canonical order and the document ends with a
newline. The format version permits future schema evolution without silently
changing the meaning of existing exports.

---

### Candidate Line

**Status:** Implemented as `Sudoku::Render::Text::candidate_line`

The candidate-line format serializes the complete candidate state as exactly 81
comma-separated fields in row-major order, from R1C1 through R9C9. Solved cells
contain their solved value. Unsolved cells contain their remaining candidates in
ascending order. A cell with no remaining candidates is represented by `-`.

Example prefix:

```text
5,3,124,26,7,2468,1489,1249,248,...
```

Command-line example:

```bash
sudoku.pl --output quiet --grid-format candidate-line --file puzzle.sdk
```

The output contains exactly 80 commas and ends with a newline. It is intended for
exact state preservation, regression fixtures, diffs, and interchange with other
tools.

---

### Compact Grid

**Status:** Implemented as `Sudoku::Render::Text::compact_grid`

The compact grid consists of nine lines of nine characters. Solved cells are shown as digits. Empty cells use a configurable character, which defaults to a period.

Example using periods:

53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79

Example using underscores:

53__7____
6__195___
_98____6_
8___6___3
4__8_3__1
7___2___6
_6____28_
___419__5
____8__79

Example using spaces:

53  7    
6  195   
 98    6 
8   6   3
4  8 3  1
7   2   6
 6    28 
   419  5
    8  79

The formatter accepts an `empty_cell_character` option:

my $text = $renderer->compact_grid(
    $grid,
    empty_cell_character => '.',
);

The default is:

empty_cell_character => '.'

The method returns a string and does not print directly.

#### Intended uses

* Concise terminal display
* Puzzle files
* Documentation examples
* Copying puzzles between applications
* Human-readable logs
* Test fixtures

---

### Puzzle String

**Status:** Implemented as `Grid::as_puzzle_string`

The puzzle-string format represents all 81 cells on one line. Empty cells are represented by zeroes.

Example:

530070000600195000098000060800060003400803001700020006060000280000419005000080079

Current interface:

my $string = $grid->as_puzzle_string;

This is currently used in stalled-puzzle status output.

The existing method always uses `0` for an empty cell. It does not insert line breaks.

#### Intended uses

* Command-line puzzle input
* Persistent puzzle identifiers
* Benchmark data files
* Program-to-program transfer where a simple fixed-width format is sufficient

---

### Simple Numeric Grid

**Status:** Implemented as `Grid::out`

The simple numeric grid prints nine rows. Each cell occupies a three-character field. Empty cells are displayed as zeroes.

Example:

     5  3  0  0  7  0  0  0  0
     6  0  0  1  9  5  0  0  0
     0  9  8  0  0  0  0  6  0
     8  0  0  0  6  0  0  0  3
     4  0  0  8  0  3  0  0  1
     7  0  0  0  2  0  0  0  6
     0  6  0  0  0  0  2  8  0
     0  0  0  4  1  9  0  0  5
     0  0  0  0  8  0  0  7  9

Current interface:

$grid->out;

The current method prints directly. It should eventually be migrated to a renderer method that returns a string.

This format may become unnecessary after the compact-grid formatter is available, but it should remain documented while it is part of the public or legacy interface.

---

### Pretty Grid

**Status:** Implemented as `Sudoku::Render::Text::pretty_grid`; legacy wrapper retained as `Grid::pretty_print`

The pretty grid includes row and column coordinates, cell boundaries, and emphasized 3×3 box boundaries.

Example:

     1   2   3   4   5   6   7   8   9
   +---+---+---+---+---+---+---+---+---+
 1 | 5 ' 3 '   |   ' 7 '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 2 | 6 '   '   | 1 ' 9 ' 5 |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 3 |   ' 9 ' 8 |   '   '   |   ' 6 '   |
   +---+---+---+---+---+---+---+---+---+
 4 | 8 '   '   |   ' 6 '   |   '   ' 3 |
   + - + - + - + - + - + - + - + - + - +
 5 | 4 '   '   | 8 '   ' 3 |   '   ' 1 |
   + - + - + - + - + - + - + - + - + - +
 6 | 7 '   '   |   ' 2 '   |   '   ' 6 |
   +---+---+---+---+---+---+---+---+---+
 7 |   ' 6 '   |   '   '   | 2 ' 8 '   |
   + - + - + - + - + - + - + - + - + - +
 8 |   '   '   | 4 ' 1 ' 9 |   '   ' 5 |
   + - + - + - + - + - + - + - + - + - +
 9 |   '   '   |   ' 8 '   |   ' 7 ' 9 |
   +---+---+---+---+---+---+---+---+---+

Current interface:

$grid->pretty_print;

The existing visual design should be retained. The implementation should be moved or adapted so that it returns a string rather than printing directly.

Renderer interface:

my $text = $renderer->pretty_grid($grid);

#### Intended uses

* Normal interactive terminal display
* Documentation
* Visual inspection of puzzle and solution states
* Explanations where row and column coordinates are useful

---

### Candidate Grid

**Status:** Implemented as `Sudoku::Render::Text::candidate_grid`; `Grid::big_print` remains as a compatibility wrapper.

The candidate grid displays each Sudoku cell as a 3×3 miniature grid. Solved cells contain their value in the center. Unsolved cells show their remaining candidates in their natural keypad positions.

Simplified example:

        1       2       3       4       5       6       7       8       9
    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
    |       '       ' 1 2 3 |       '       '       |       '       '       |
  1 |   5   '   3   ' 4 6   | 2 6   '   7   ' 2 4 6 | 1 4   ' 1 2 4 ' 2 4   |
    |       '       '   8 9 |       '       '   8   |   9   '       '   8   |
    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +

The complete output is much larger than the solved-value formats.

Current interface:

$grid->big_print;

The current method prints directly. It is used by debug output and by the `--trace-grid-after-deduction` option.

Proposed renderer interface:

my $text = $renderer->candidate_grid($grid);

#### Intended uses

* Strategy development
* Debugging
* Candidate-state inspection
* Diagnosing stalled puzzles
* Showing the grid after individual deductions

---

### Worksheet Grid

**Status:** Implemented as `Sudoku::Render::Text::worksheet_grid`.

The worksheet grid uses the same candidate-sized 3×3 miniature-cell layout as
the candidate grid. Solved cells contain their value in the center. Unsolved
cells remain blank, making the format useful for printing or sharing a puzzle
without revealing candidate state.

Renderer interface:

my $text = $renderer->worksheet_grid($grid);

Command-line interface:

sudoku.pl --output quiet --grid-format worksheet --file puzzle.sdk

#### Intended uses

* Printed puzzle worksheets
* Sharing puzzle state without candidate hints
* Large-cell terminal display

---

### Cell Status List

**Status:** Implemented as `Grid::status`

The cell-status list prints one line for each of the 81 cells. Each line reports the row, column, and box, followed by either the fixed value or the remaining candidates.

Example:

Showing status of all cells:
( 1, 1, 1 ) Given:    5
( 1, 2, 1 ) Given:    3
( 1, 3, 1 ) 3 left -> 1, 2, 4
( 1, 4, 2 ) 2 left -> 2, 6
( 1, 5, 2 ) Given:    7

Current interface:

$grid->status;

The current method prints directly.

#### Intended uses

* Low-level debugging
* Inspecting cell metadata
* Verifying candidate propagation

This is a diagnostic representation rather than a routine user-facing grid format.

---

### Multi-Column Cell Status

**Status:** Implemented as `Grid::multi_column_status`

This contains the same information as the cell-status list, arranged in multiple columns to reduce vertical length.

Conceptual example:

Showing status of all cells:
( 1, 1, 1 ) Given: 5       ( 4, 1, 4 ) Given: 8       ( 7, 1, 7 ) 3 left -> 1, 3, 9
( 1, 2, 1 ) Given: 3       ( 4, 2, 4 ) 3 left -> ...  ( 7, 2, 7 ) Given: 6

Current interface:

$grid->multi_column_status;

The current method prints directly.

#### Intended uses

* Developer diagnostics
* Reviewing all cell states while using less vertical terminal space

---

### Individual Cell Status

**Status:** Implemented as `Cell::show_my_possibilities`

This displays one cell and either its assigned value or its remaining candidates.

Examples:

Cell at ( 1, 1, 1 ) Given: 5

Cell at ( 1, 3, 1 ) Possibilities left: 3 -> 1, 2, 4

Current interface:

$cell->show_my_possibilities;

The current method prints directly.

This is a developer diagnostic format rather than a complete-grid format.

## Solver Narration Modes

Solver narration determines how much of the solving process is reported. It does not by itself determine the grid representation.

The command-line option is:

--output MODE

Supported modes are:

quiet
normal
puzzle
explain
trace
debug

### Puzzle Mode

**Status:** Implemented

Renders the input puzzle as loaded and exits before solving. It can be combined
with `--grid-format` and `--character-set` when the caller wants a specific
view of the original puzzle.

Example:

sudoku.pl --output puzzle --grid-format worksheet --file puzzle.sdk

### Quiet Mode

**Status:** Implemented

Suppresses solver narration and final status output.

Example:

sudoku.pl --output quiet --file puzzle.sdk

Output:


Quiet mode is useful when the caller is interested only in the process exit status or is using the solver through a programmatic interface.

---

### Normal Mode

**Status:** Implemented and default

Prints only the final solved, stalled, or contradiction report.

Example:

Solved
------
Solved all 81 cells in 64 deductions.
Difficulty: Hard (method v1.0)
Solution: 534678912672195348198342567859761423426853791713924856961537284287419635345286179

Normal mode does not print pass boundaries, strategy attempts, restart notices, or individual deductions.

---

### Explain Mode

**Status:** Implemented

Prints each deduction in human-readable form, followed by the final status report.

Example:

Hidden Single in Box 7:
    Set R9C2 = 6
    Why: Candidate 6 appears only once in this box.

Naked Pairs:
    Remove candidate 4 from R7C3
    Why: R7C1 and R7C2 contain the naked pair 4,9.

Solved
------
Solved all 81 cells in 64 deductions.
Difficulty: Hard (method v1.0)
Solution: 534678912672195348198342567859761423426853791713924856961537284287419635345286179

Explain mode reports applied deductions but omits unsuccessful strategy attempts and solver-control-flow details.

---

### Trace Mode

**Status:** Implemented

Prints pass boundaries, every strategy attempt, applied deductions, restart notices, and final status.

Example:

Pass 1
------

    Naked Singles: no deductions
    Hidden Singles: applied 1 deduction
Hidden Single in Box 7:
    Set R9C2 = 6
    Why: Candidate 6 appears only once in this box.
    Restarting from Naked Singles.
End Pass 1: applied 1 deduction

Pass 2
------

    Naked Singles: applied 1 deduction
Naked Singles:
    Set R8C2 = 8
    Why: Candidate 8 is the only remaining possibility for R8C2.
    Restarting from Naked Singles.
End Pass 2: applied 1 deduction

---

### Debug Mode

**Status:** Implemented

Includes trace output plus full candidate grids at diagnostic points.

Example:

Hidden Single in Box 7:
    Set R9C2 = 6
    Why: Candidate 6 appears only once in this box.
Grid after deduction 12:

        1       2       3       4       5       6       7       8       9
    +-------+-------+-------+-------+-------+-------+-------+-------+-------+
    ...

Debug mode is intended for solver and strategy development, not normal puzzle solving.

## Solver Narration Elements

The text renderer currently provides the following individual narration elements.

### Pass Start

Pass 3
------

Renderer method:

$renderer->pass_start($pass);

### Pass End

End Pass 3: applied 1 deduction

or:

End Pass 3: no progress

Renderer method:

$renderer->pass_end($pass, $progress);

### Strategy Result

    Naked Singles: no deductions

    Hidden Singles: applied 1 deduction

Renderer method:

$renderer->strategy_result($strategy_name, $count);

### Restart Notice

    Restarting from Naked Singles.

Renderer method:

$renderer->restart_notice;

### Deduction

Set-value example:

Hidden Single in Box 7:
    Set R9C2 = 6
    Why: Candidate 6 appears only once in Box 7.
    Detail: R9C2 must be 6.

Candidate-removal example:

X-Wing:
    Remove candidate 7 from R8C4
    Why: Candidate 7 forms an X-Wing in rows 2 and 6.

Renderer method:

$renderer->deduction($deduction);

### Debug Grid Header

Grid after deduction 12:

Renderer method:

$renderer->debug_grid_header($deduction_number);

## Final Result Reports

### Solved Result

**Status:** Implemented

Solved
------
Solved all 81 cells in 64 deductions.
Difficulty: Hard (method v1.0)
Solution: 534678912672195348198342567859761423426853791713924856961537284287419635345286179

### Stalled Result

**Status:** Implemented

Stalled
-------
Solved cells: 21 / 81
Remaining cells: 60
Deductions applied: 4
Difficulty so far: Medium (method v1.0)
Puzzle state: 530070000600195000098000060800060003400803001700020006060000280000419005000080079
No registered strategy can make further progress.

### Contradiction Result

**Status:** Implemented

Contradiction
-------------
R4C7 has no remaining candidates.
Solved cells: 35 / 81
Deductions applied: 18
Difficulty so far: Hard (method v1.0)

All three reports are produced by:

$renderer->final_status($solver, $grid);

## Benchmark Report

**Status:** Implemented as `Sudoku::Benchmark::summary_text`

The benchmark report summarizes a collection of puzzles.

Example:

Canonical 17-Clue Benchmark
===========================

Benchmark file:
    Puzzles/Puzzle_Dispatch_20191209.txt

Puzzles processed : 1
Solved            : 1
Stalled           : 0
Contradictions    : 0

Average solve time: 0.006124 s
Total time        : 0.006124 s

Highest strategy usage

    Hidden Pairs                58
    Hidden Singles             448
    Naked Pairs                 67

Strategy contributions

    Strategy                     Puzzles  Deductions  Cells  Eliminations
    ---------------------------  -------  ----------  -----  ------------
    Naked Singles                    998       38827  38827             0
    Hidden Singles                  1000       23873  23873             0

Command-line interface:

sudoku.pl --benchmark Puzzles/Puzzle_Dispatch_20191209.txt

Programmatic interface:

my $text = $benchmark->summary_text;

The benchmark formatter already follows the preferred return-a-string design.

## Utility Output

### Version

**Status:** Implemented

SudokuSolver 0.7.0

Command:

sudoku.pl --version

### Command-Line Help

**Status:** Implemented through POD

The help output documents command-line syntax and available options.

Command:

sudoku.pl --help

## Planned Enhanced Formats

The enhanced-output roadmap is:

1. Compact and pretty grid formats
2. Machine-readable JSON output
3. CSV or TSV result output
4. One-line puzzle/solution output
5. Unicode versus plain-ASCII grids
6. Output directed to a file
7. Stable renderer event objects or hashes
8. Color as an optional final layer

### Machine-Readable JSON

**Status:** Planned

Expected uses include recording a solve result, deductions, difficulty, timing, and final grid state.

Conceptual example:

{
  "status": "solved",
  "puzzle": "530070000600195000098000060800060003400803001700020006060000280000419005000080079",
  "solution": "534678912672195348198342567859761423426853791713924856961537284287419635345286179",
  "solved_cells": 81,
  "deductions": 64,
  "difficulty": {
    "label": "Hard",
    "method_version": "1.0"
  }
}

### CSV and TSV Results

**Status:** Planned

Expected primarily for batch solving and benchmark analysis.

CSV example:

index,status,solved_cells,deductions,difficulty,elapsed_seconds,solution
1,solved,81,64,Hard,0.038861,534678912672195348198342567859761423426853791713924856961537284287419635345286179
2,stalled,62,41,Expert,0.052113,

TSV would contain the same fields separated by tab characters.

### One-Line Puzzle or Solution Output

**Status:** Partially implemented

The underlying 81-character representations already exist, but a dedicated command-line output format is planned.

Puzzle example:

530070000600195000098000060800060003400803001700020006060000280000419005000080079

Solution example:

534678912672195348198342567859761423426853791713924856961537284287419635345286179

### ASCII and Unicode Grid Styles

**Status:** Planned

ASCII example:

   +---+---+---+
   | 5 | 3 |   |

Unicode example:

   ┌───┬───┬───┐
   │ 5 │ 3 │   │

Unicode should be an optional presentation choice. Plain ASCII should remain fully supported.

### Output Directed to a File

**Status:** Implemented

Command-line use:

```bash
sudoku.pl --output-file result.txt --file puzzle.sdk
```

The option redirects normal narration, selected grid formats, JSON results,
benchmark summaries, and discovery listings. The destination is written as
UTF-8 and replaced if it already exists. Fatal errors remain on standard error.

Rendering methods return strings so that the caller can send the same output to
standard output, a file, a test capture, or another consumer.

### Stable Renderer Events

**Status:** Planned

Solver activity should eventually be represented as stable structured events before text rendering.

Conceptual event:

{
    type          => 'deduction',
    strategy      => 'Hidden Singles',
    action        => 'set_value',
    row           => 8,
    column        => 1,
    value         => 6,
    reason        => 'Candidate 6 appears only once in Box 7.',
    deduction_num => 12,
}

Text, JSON, CSV, and future renderers could consume these events without changing solver logic.

### Color

**Status:** Planned as a final presentation layer

Color may distinguish:

* Given clues
* Solver-entered values
* Candidates
* Removed candidates
* Strategy names
* Warnings
* Contradictions
* Successful completion

Color must be optional and must not be embedded in the underlying grid or event data.

## Rendering Design Rule

New formatter methods should return complete strings:

my $text = $renderer->compact_grid($grid);
my $text = $renderer->pretty_grid($grid);
my $text = $renderer->candidate_grid($grid);
my $text = $renderer->final_status($solver, $grid);

They should not print directly.

The command-line program decides where the returned text is sent:

print $text;

or, later:

print {$output_handle} $text;

This separation allows the same renderer to support terminal output, files, tests, logs, JSON containers, and other user interfaces.


### Candidate List

The `candidate-list` format prints one labeled line per Sudoku row. Solved
cells contain their value. Unsolved cells contain every remaining candidate in
ascending order. A cell with no remaining candidates is shown as `-`.

```text
R1: 5 3 124 26 7 2468 1489 1249 248
R2: 6 247 247 1 9 5 3478 234 2478
...
R9: 123 1245 12345 2356 8 26 1346 7 9
```

Command-line example:

```bash
perl -Ilib bin/sudoku.pl --output quiet --grid-format candidate-list --file puzzle.sdk
```

This is a human-readable candidate-state view. The later single-line and JSON
exports are the preferred machine-interchange formats.


## General JSON Solve Result

Use `--result-format json` for one structured document describing the complete solve result.
It includes status, original puzzle, current grid, solved and remaining cell counts,
deduction statistics, difficulty metadata, solution when solved, and structured
contradiction information when applicable.

```bash
sudoku.pl --result-format json --file puzzle.sdk
```

This option suppresses human narration so standard output remains valid JSON.


## One-Line Puzzle, Grid, and Solution Formats

Three named grid formats provide newline-terminated 81-character records:

- `puzzle-line` emits only the original givens and uses `0` for every other cell.
- `grid-line` emits the current grid state and uses `0` for unsolved cells.
- `solution-line` emits all 81 solved values and rejects an unsolved grid.

```bash
sudoku.pl --output quiet --grid-format puzzle-line --file puzzle.sdk
sudoku.pl --output quiet --grid-format grid-line --file puzzle.sdk
sudoku.pl --output quiet --grid-format solution-line --file puzzle.sdk
```

The library methods `puzzle_line` and `grid_line` accept an optional
`empty_cell_character` argument when a character other than `0` is required.
`solution-line` never contains an empty-cell marker.


## CSV and TSV Solve Results

Use `--result-format csv` or `--result-format tsv` to produce a stable tabular
solve record. Each document contains one header row and one result row.

```bash
sudoku.pl --result-format csv --file puzzle.sdk
sudoku.pl --result-format tsv --file puzzle.sdk
```

The columns are:

```text
status
puzzle
current_grid
solution
solved_cells
remaining_cells
deductions
difficulty_label
difficulty_score
difficulty_rating_version
statistics_json
contradiction_kind
contradiction_message
contradiction_location
contradiction_explanation
```

CSV follows standard double-quote escaping. TSV escapes backslashes, tabs,
carriage returns, and newlines within fields. Nested strategy statistics remain
available without flattening through the canonical JSON value in
`statistics_json`. Contradiction columns are empty for solved and stalled
results.

Document and image grid renderers
---------------------------------

The named grid-format registry also provides export-oriented renderers:

- `markdown` emits a pipe-table suitable for README files and issue reports.
- `html` emits a standalone UTF-8 HTML document with an accessible table.
- `svg` emits a standalone scalable vector image.
- `png` emits a 450 by 450 pixel PNG image.
- `pdf` emits a one-page vector PDF using a standard built-in font.

PNG and PDF are binary formats and therefore require `--output-file` at the
command line. Markdown, HTML, and SVG may be written to standard output or to a
file. These renderers deliberately do not contain ANSI terminal styling.

Examples:

    bin/sudoku.pl --output quiet --grid-format markdown \
        --file Puzzles/Puzzle3.txt

    bin/sudoku.pl --output quiet --grid-format html \
        --output-file puzzle.html --file Puzzles/Puzzle3.txt

    bin/sudoku.pl --output quiet --grid-format svg \
        --output-file puzzle.svg --file Puzzles/Puzzle3.txt

    bin/sudoku.pl --output quiet --grid-format png \
        --output-file puzzle.png --file Puzzles/Puzzle3.txt

    bin/sudoku.pl --output quiet --grid-format pdf \
        --output-file puzzle.pdf --file Puzzles/Puzzle3.txt

Mixed-weight Unicode grids
--------------------------

`UNICODE_MIXED` uses heavy lines for the outside border and 3-by-3 box
boundaries, with light lines between individual cells. The implementation uses
the corresponding mixed-weight Unicode junction characters, so all crossings
and tees join correctly.
