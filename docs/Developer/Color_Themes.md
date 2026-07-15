# Color Themes

SudokuSolver keeps color activation separate from theme selection.

```text
--color auto|always|never
--color-theme subtle|bright|greyscale
```

`auto` is the default and emits ANSI styling only when standard output is a
terminal. `always` is useful for terminal capture tools that understand ANSI
escape sequences. `never` guarantees plain human-readable text.

Structured JSON, CSV, and TSV result formats are always plain and reject
`--color always`. One-line and interchange-oriented grid formats do not insert
ANSI sequences.

## Included themes

- `subtle` is the default low-intensity theme.
- `bright` uses high-contrast ANSI colors.
- `greyscale` uses attributes such as bold, dim, underline, and reverse video
  without depending on color hue.

List installed themes with:

```text
bin/sudoku.pl --list-color-themes
```

## Theme files

Themes are data files in `themes/`. Each line maps a semantic role to one or
more ANSI style names:

```text
heading = bold cyan
success = green
warning = yellow
error = red
```

Supported semantic roles currently include headings, givens, solved values,
empty cells, candidates, strategies, explanations, success, warning, error,
statistics, filenames, and emphasis. Renderers request semantic roles; they do
not embed theme-specific escape codes.

The shared grid builder measures visible width after ignoring ANSI Select
Graphic Rendition sequences. Colored cells therefore preserve the alignment of
ASCII and Unicode grid borders.
