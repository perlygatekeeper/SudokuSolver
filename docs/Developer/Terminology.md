# SudokuSolver Terminology Guide

This document defines the authoritative terminology for SudokuSolver. It is the
reference for source code, command-line help, documentation, tests, corpus
metadata, generated puzzle files, and release notes.

The words **MUST**, **MUST NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** express
requirements and recommendations within the project.

## Core Sudoku Terms

### Cell

One of the 81 positions in a standard 9×9 Sudoku grid.

A cell is identified by its row and column. `R4C7`, for example, means the cell
at row 4, column 7. Rows and columns are numbered 1 through 9.

### Unit

A set of nine cells that must contain the digits 1 through 9 exactly once in a
completed Sudoku:

- a **row**;
- a **column**; or
- a **box**.

Use **unit** when a statement applies equally to rows, columns, and boxes.

### Box

One of the nine 3×3 regions in a standard Sudoku grid.

Use **box**, not *block*, *region*, or *subgrid*, in project documentation and
user-facing output. Those alternatives may be used only when quoting or
interoperating with an external format that uses different terminology.

Boxes are numbered from 1 through 9 in reading order.

### Band

A horizontal group of three adjacent boxes, and therefore three adjacent rows.
There are three bands.

### Stack

A vertical group of three adjacent boxes, and therefore three adjacent columns.
There are three stacks.

This sense of **stack** is specific to Sudoku geometry and should not be confused
with a program data structure.

### Peer

Any cell that shares a row, column, or box with a given cell. A standard Sudoku
cell has 20 distinct peers.

### Given

A digit supplied as part of the original puzzle. A given is fixed and is not a
deduction made by the solver.

**Given** is the preferred term when discussing an individual fixed digit.

### Clue

A given considered as part of the puzzle's clue set. **Clue count** is the
number of givens in the original puzzle.

In ordinary prose, **given** and **clue** are closely related. Prefer **given**
for the digit in a particular cell and **clue** when discussing counts,
patterns, symmetry, or puzzle construction.

### Candidate

A digit that remains possible in an unsolved cell under the current solver
state.

The **candidate set** for a cell is the complete set of its remaining possible
digits. Candidate data describes a solver state, not merely the original
puzzle, unless explicitly labeled as the initial candidate state.

### Placement

The act or result of assigning a digit to a cell by deduction.

### Elimination

The act or result of removing a digit from a cell's candidate set by deduction.

### Deduction

One logically justified solver step. A deduction may produce one or more
placements, eliminations, or both.

Do not use **move** as the formal name for a deduction. It is acceptable only in
informal explanatory prose.

### Strategy

A named logical method used to derive deductions, such as Hidden Singles,
X-Wing, or XY-Chain.

Strategy names are proper project labels and SHOULD use the spelling and
capitalization in the strategy registry.

### Technique

An informal synonym for **strategy**. Use **strategy** in metadata, APIs, CLI
output, and normative documentation.

## Puzzle and Solution Terms

### Grid

An arrangement of 81 cells. **Grid** describes structure or representation and
does not, by itself, imply whether the cells contain a puzzle, a solution, or an
intermediate solver state.

### Puzzle

A valid Sudoku problem consisting of givens and empty cells, intended to have
exactly one solution.

When provenance matters, **puzzle** refers to the supplied arrangement exactly
as presented, before canonicalization or randomization.

Do not use **puzzle** to mean its solution, its canonical representative, or an
arbitrary intermediate solver state.

### Puzzle string

An 81-character, row-major representation of a puzzle. Digits `1` through `9`
represent givens. A designated empty-cell character—normally `.`—represents an
empty cell.

When accepting external input, the software MAY support other empty-cell
characters. Persisted project data SHOULD use one documented representation.

### Solution

A completely filled valid Sudoku grid satisfying every given in the puzzle.

### Solution string

An 81-digit, row-major representation of a solution. It contains no empty-cell
characters.

### Solver state

The complete state of a solving attempt at a particular moment, including
placed digits and all remaining candidates.

### Solved

A solver outcome in which all 81 cells have been filled and the completed grid
has been validated.

### Stalled

A solver outcome in which the puzzle remains incomplete, no enabled strategy
can make another deduction, and no contradiction has been found.

**Stalled** does not mean invalid, unsolvable, or non-unique. It describes the
capability of a particular solver configuration.

### Contradiction

A solver state that cannot lead to a valid solution—for example, an unsolved
cell with no candidates or a unit that can no longer contain a required digit.

### Valid puzzle

A puzzle whose givens do not violate Sudoku constraints and that satisfies the
project's stated validity requirements. If uniqueness has not been checked,
documentation MUST say so explicitly.

### Unique puzzle

A valid puzzle with exactly one solution.

### Minimal puzzle

A unique puzzle for which removing any single clue destroys uniqueness.

**Minimal** does not mean that the puzzle has the smallest possible clue count,
nor does it mean canonical.

## Equivalence and Canonicalization

### Equivalence-preserving transform

An operation that changes a puzzle's presentation while preserving its Sudoku
structure and solution behavior. Supported transforms include:

- relabeling digits;
- permuting rows within a band;
- permuting columns within a stack;
- permuting bands;
- permuting stacks;
- transposing the grid; and
- other explicitly supported geometric symmetries.

Use **transform** for the operation and **transformed puzzle** for its result.

### Equivalent puzzles

Two puzzles related by the project's defined set of equivalence-preserving
transforms.

Equivalent puzzles may look different, have different puzzle strings, and have
different clue coordinates. For corpus identity, they represent the same
underlying puzzle class.

### Equivalence class

The complete set of puzzles equivalent to one another under the project's
defined transforms.

The exact set of allowed transforms is part of the canonicalization
specification. Changing that set can change canonical representatives and MUST
be treated as a format or algorithm version change.

### Normalization

A deterministic reduction that puts some aspect of a puzzle into a standard
form, often as one stage of canonicalization.

Normalization is not necessarily complete canonicalization. For example, a
row-normal form may reduce the search space without selecting the final
representative of the entire equivalence class.

### Row-normal form

The deterministic normalized form produced by the project's row-normalization
rules. It is an intermediate canonicalization representation unless the
relevant specification explicitly states otherwise.

Hyphenate **row-normal** when used adjectivally.

### Canonicalization

The deterministic process of selecting exactly one representative from an
equivalence class.

Canonicalization MUST give the same result for every member of the same
equivalence class when the same canonicalization version is used.

### Canonical form

The normalized representation chosen by the canonicalization algorithm. In
SudokuSolver, the canonical form is selected deterministically, normally by a
defined lexicographic comparison.

### Canonical puzzle

The unique puzzle selected as the representative of an equivalence class by a
specific version of the canonicalization algorithm.

**Canonical puzzle** refers to the representative itself. It does not refer to
every equivalent source puzzle, and it is not synonymous with **minimal
puzzle**.

### Canonical puzzle string

The 81-character puzzle string of a canonical puzzle.

### Lexicographic minimum

The smallest representation under the project's explicitly defined character
ordering and comparison rules.

Documentation MUST NOT assume that “smallest” is self-explanatory. The compared
representation and ordering rules belong to the canonicalization
specification.

### Witness transform

The recorded transform that maps a source puzzle to its canonical puzzle.

A witness transform provides reproducibility and an auditable relationship
between a source representation and the canonical representative. It is
evidence of equivalence, not the identity of the puzzle.

If several transforms produce the same canonical result, the implementation
MUST use a deterministic rule when it persists one witness transform.

### Canonicalization version

An identifier for the precise canonicalization rules, transform set, comparison
representation, and tie-breaking behavior used to select canonical puzzles.

Canonical data SHOULD always record this version. A software release version
and a canonicalization version are distinct even when their values happen to
match.

## Identity and Encoding

### Fingerprint

A deterministic, content-derived encoding of a canonical puzzle. The planned
corpus fingerprint groups clue coordinates by digit in digit order, using a
documented delimiter and coordinate scheme.

A fingerprint:

- is derived from canonical puzzle content;
- is stable only under its declared fingerprint and canonicalization versions;
- can be independently recomputed; and
- is intended to identify equivalent source puzzles through their common
  canonical puzzle.

Do not use **fingerprint** for a sequential database key or corpus row number.
Do not call it a cryptographic hash unless it actually is one and the algorithm
is named.

### Fingerprint format version

An identifier for the rules used to encode a canonical puzzle as a fingerprint.
This version is distinct from the canonicalization version because either may
change without the other.

### Canonical ID

A stable, human-readable identifier assigned to a canonical corpus record, such
as `17C-000001`.

A Canonical ID:

- identifies a record in a particular corpus identity system;
- is assigned, not derived from puzzle content;
- remains attached to the same canonical record across metadata rebuilds; and
- MUST NOT be inferred from a file line number unless the corpus specification
  explicitly guarantees that relationship.

Use **Canonical ID** with both words capitalized in prose. Field and function
names may follow the conventions of their implementation language.

### Source ID

An identifier supplied by, or derived from, an upstream puzzle collection. A
source ID preserves provenance and MUST NOT be substituted for a Canonical ID.

### Record

One structured corpus entry describing a canonical puzzle and its associated
identity, provenance, solution, rating, symmetry, and version metadata.

### Encoding

A reversible representation of information according to documented rules.
Encoding is not encryption and does not, by itself, imply compression.

### Decode

To reconstruct the represented information from an encoding. Decoding a
fingerprint reconstructs its encoded canonical clue data; it does not discover
the solution unless the solution is part of that encoding.

## Corpus Terms

### Corpus

The project-managed collection of canonical Sudoku records together with the
rules, metadata, versions, and provenance needed to interpret them.

The **corpus** is the logical dataset. It is not merely a directory, one source
file, or an arbitrary batch of puzzles.

### Source collection

An external or preliminary collection from which corpus puzzles originate. A
source collection may contain duplicates under canonical equivalence and may
lack project metadata.

### Definitive corpus

The authoritative, versioned set of canonical records recognized by a SudokuSolver
release. For the 17-clue project corpus, the intended definitive set contains
49,158 distinct canonical puzzles.

Use **definitive** to indicate project authority, not a claim that no other
Sudoku collection can exist or that the mathematical universe of puzzles has
been exhausted.

### Master file

The authoritative serialized file containing the complete definitive corpus in
its published interchange form.

The master file is a physical artifact; the corpus is the logical dataset it
represents. Derived indexes, reports, and caches are not master files.

### Corpus version

An identifier for a published corpus dataset. It covers membership, assigned
identities, required fields, and the interpretation of its records.

A corpus version is distinct from the SudokuSolver software release version,
canonicalization version, fingerprint format version, and rating version.

### Corpus membership

The condition of a canonical puzzle being included in a specified corpus
version.

### Corpus index

A derived structure that supports lookup, sorting, or selection of corpus
records. An index MAY be rebuilt from the master file and MUST NOT silently
become a competing source of truth.

### Canonical index

The derived mapping produced by canonicalizing source puzzles and associating
source records with canonical representations. It is an intermediate or
supporting artifact unless explicitly designated as the master file.

### Identity table

A derived or build-stage mapping between canonical puzzles, fingerprints, and
Canonical IDs.

### Solution table

A derived or build-stage mapping between canonical records and their complete
solutions.

### Duplicate

A source puzzle whose canonical puzzle is already represented by another
source record under the same canonicalization version.

Two byte-identical puzzle strings are exact duplicates. Two different puzzle
strings with the same canonical puzzle are canonical duplicates. State which
meaning is intended when the distinction matters.

### Provenance

The recorded origin and processing history of a puzzle or corpus record.
Provenance may include the source collection, source ID, import date,
canonicalization version, witness transform, generation seed, and processing
steps.

### Derived artifact

A file or dataset reproducibly generated from authoritative inputs, such as an
index, rating report, solution table, or benchmark summary.

Derived artifacts SHOULD document their inputs and generating versions. They
MUST NOT be described as authoritative when the master file is the source of
truth.

## Rating and Solver-Result Terms

### Difficulty

A versioned classification of how demanding a puzzle is under a declared
rating system. Difficulty is metadata produced by a rater; it is not an
intrinsic, universal property independent of algorithms and settings.

Difficulty labels MUST be accompanied, directly or by schema definition, by a
rating version.

### Difficulty label

A named category such as Easy, Moderate, Hard, or Expert, as defined by a
specific rating version.

The project MUST NOT assume that labels from unrelated Sudoku applications are
equivalent.

### Score

A numeric rating value calculated under a declared rating version. The score
supports ordering or grouping puzzles within the semantics of that rating
system.

A score from one rating version MUST NOT be compared directly with a score from
another unless compatibility is explicitly defined.

### Rating version

An identifier for the strategies, ordering, weights, tie-breaking rules, solver
configuration, and calculation used to assign difficulty metadata.

### Highest required strategy

The most advanced strategy required by a successful solve, according to the
ordered strategy hierarchy of a declared rating version.

This term does not mean the rarest strategy used, the final strategy used, or
the strategy producing the most deductions.

### Strategy usage

The record of whether, how often, or with what effects a strategy participated
in solving one or more puzzles. Reports MUST state whether counts refer to
puzzles, deductions, placements, cells, or eliminations.

### Solve time

Elapsed time spent by a particular solver build and configuration on a solving
operation. Solve time is benchmark data, not stable puzzle identity or rating
metadata, unless a rating specification explicitly incorporates it.

### Benchmark

A repeatable measurement run over a declared puzzle set, software version,
configuration, and environment.

### Benchmark corpus

A puzzle collection selected for performance or capability measurement. A
benchmark corpus is not necessarily the definitive corpus.

## Symmetry Terms

### Clue-pattern symmetry

Symmetry of the occupied-versus-empty cell pattern, without regard to the digit
values in occupied cells.

Unless explicitly stated otherwise, corpus symmetry metadata refers to
clue-pattern symmetry.

### Symmetric puzzle

A puzzle whose clue pattern is invariant under at least one supported,
non-identity symmetry.

### Asymmetric puzzle

A puzzle whose clue pattern has none of the supported, non-identity symmetries.

Within the corpus API, **asymmetric** is relative to the project's deliberately
limited set of human-identifiable symmetry classifications. It does not assert
the absence of every possible mathematical automorphism.

### Supported symmetry names

Corpus metadata and selection APIs use these exact lowercase identifiers:

- `rotation-180`
- `rotation-90`
- `reflection-horizontal`
- `reflection-vertical`
- `reflection-main-diagonal`
- `reflection-anti-diagonal`

User-facing prose may use natural capitalization, such as “180-degree
rotational symmetry,” but persisted values and API arguments SHOULD use the
identifiers above.

### Rotation-180 symmetry

Clue-pattern invariance under a 180-degree rotation about the center cell.

### Rotation-90 symmetry

Clue-pattern invariance under a 90-degree rotation about the center cell. Such a
pattern is necessarily also invariant under 180-degree rotation, but both
metadata values MAY be recorded when the schema permits multiple symmetries.

### Horizontal reflection symmetry

Clue-pattern invariance under reflection across the horizontal axis through the
center of the grid.

### Vertical reflection symmetry

Clue-pattern invariance under reflection across the vertical axis through the
center of the grid.

### Main-diagonal reflection symmetry

Clue-pattern invariance under reflection across the diagonal from `R1C1` to
`R9C9`.

### Anti-diagonal reflection symmetry

Clue-pattern invariance under reflection across the diagonal from `R1C9` to
`R9C1`.

### Automorphism

A structure-preserving mapping of a mathematical object to itself. The corpus
symmetry feature does not attempt a complete automorphism-group analysis.

Avoid **automorphism** in ordinary corpus documentation unless discussing this
explicit limitation or a separate mathematical feature.

## Generation Terms

### Puzzle generation

The reproducible process of producing a playable puzzle and its provenance from
declared inputs and rules.

### Generated puzzle

A puzzle emitted by the generation pipeline. It may be an equivalent transform
of a corpus puzzle, a clue-augmented form of one, or another documented output
of the selected generation mode.

Do not imply that every generated puzzle is a new canonical corpus member.

### Base puzzle

The puzzle selected as the starting point for a generation operation, normally
a canonical corpus puzzle.

### Randomization

Application of one or more randomly selected equivalence-preserving transforms
to alter presentation while preserving underlying Sudoku structure.

### Symmetry randomization

Randomization using Sudoku equivalence transforms such as digit relabeling,
row, column, band, and stack permutations, and supported geometric transforms.

This term concerns equivalence transforms; it is distinct from classifying the
visual symmetry of a clue pattern.

### Reveal

The addition of a solution digit as a new clue during generation.

Reveals increase clue count and may change rated difficulty and clue-pattern
symmetry. They do not preserve canonical equivalence with the base puzzle
because they change the clue set.

### Target clue count

The requested number of clues in a generated puzzle. It is a generation goal,
not an assertion that every seed or selection policy can satisfy the goal under
all other constraints.

### Target difficulty

The requested difficulty classification or range for a generated puzzle under
a declared rating version.

### Seed

The explicit value used to initialize deterministic pseudorandom choices in a
generation run.

The same seed is reproducible only when the relevant generator version,
algorithm, inputs, and options are also the same.

### Generation step

One recorded operation in a generation run, such as corpus selection, a
transform, a reveal, or a rating decision.

### Generation provenance

The metadata needed to audit and reproduce a generated puzzle, including at
least the base Canonical ID or fingerprint, generator version, seed, options,
and ordered generation steps.

### Generator version

An identifier for the exact generation algorithm and its deterministic
behavior. It is distinct from the software release and corpus versions.

## Query Terms

### Corpus query

A read-only selection over corpus records using one or more declared criteria.

### Filter

A condition that a corpus record must satisfy to be included in query results,
such as a clue count, difficulty label, score range, highest required strategy,
or symmetry.

### Selector

A value or callable interface used to identify or choose records. Prefer
**filter** when the operation narrows a set by a condition and **lookup** when
it requests a unique identity.

### Lookup

A query intended to retrieve a specific record by a unique key, normally a
Canonical ID or fingerprint.

### Sort key

A metadata field used to order query results. Sorting MUST define tie-breaking
behavior when stable reproducibility matters.

### Multiple selection

A query result containing zero, one, or many corpus records. Filter helpers
SHOULD support multiple results; identity lookups SHOULD return at most one
record or report an integrity error.

## Output and Interface Terms

### Content mode

The amount and kind of information emitted by a solve operation. The standard
content modes are:

- `quiet` — machine-oriented minimal output;
- `normal` — default user-facing output;
- `explain` — successful deductions and their explanations;
- `trace` — decision flow, including unsuccessful strategy attempts where
  defined; and
- `debug` — internal diagnostic detail.

Content mode answers **what information is emitted**.

### Grid format

The representation used to render a grid or grid-related data, such as
`pretty`, `compact`, `markdown`, `html`, `svg`, `png`, `pdf`, or a line-oriented
format.

Grid format answers **how grid data is represented**. It is orthogonal to
content mode.

### Character set

The collection of glyphs used to draw a text grid, such as ASCII or a Unicode
line style. Character set is a rendering choice within applicable grid formats;
it is not a content mode.

### Renderer

A component that converts solver or grid data into a particular output
representation.

### Renderer event

A stable structured description of something to be rendered, separated from
the final textual or graphical presentation.

### Candidate export

An output containing all remaining candidates for all 81 cells in a solver
state. A candidate export MUST preserve cell order and distinguish solved cells,
empty candidate sets, and ordinary candidate sets according to its format
specification.

### Human-readable

Designed primarily for people to read. Human-readable output may prioritize
labels, spacing, and explanations over rigid interchange stability.

### Machine-readable

Defined by a stable syntax and schema suitable for programmatic consumption.
Machine-readable does not necessarily mean compact.

### Interchange format

A documented machine-readable representation intended to transfer data between
programs or versions.

## Version Terms

### Software version

The version of SudokuSolver as a whole, such as `1.2.0`.

### Format version

The version of a persisted syntax or schema. A format version changes when old
readers cannot safely interpret new data or when the meaning of existing data
changes.

### Algorithm version

The version of a deterministic procedure whose exact results matter, such as
canonicalization, rating, or generation.

### Schema version

The version of the field structure and interpretation for a structured record
or file.

### Compatibility

The declared ability of one version to read, reproduce, compare, or otherwise
work correctly with data from another version. Compatibility MUST be stated for
the specific artifact or algorithm; a shared software major version alone does
not guarantee it.

## Required Distinctions

The following terms MUST remain distinct throughout the project:

| Do not conflate | Distinction |
| --- | --- |
| Puzzle / solution | A problem with empty cells versus its completed grid. |
| Puzzle / solver state | Original givens versus mutable placements and candidates. |
| Given / candidate | A fixed input digit versus a currently possible digit. |
| Canonical puzzle / minimal puzzle | Equivalence-class representative versus clue-removal minimality. |
| Canonical form / row-normal form | Final representative versus an intermediate normalization. |
| Fingerprint / Canonical ID | Content-derived encoding versus assigned stable identifier. |
| Canonical ID / source ID | Project corpus identity versus upstream provenance identity. |
| Corpus / master file | Logical versioned dataset versus its authoritative serialization. |
| Master file / derived artifact | Source of truth versus reproducible output built from it. |
| Corpus version / software version | Dataset identity versus application release identity. |
| Canonicalization version / fingerprint format version | Representative-selection rules versus encoding rules. |
| Difficulty / score | Categorical rating versus numeric rating value. |
| Difficulty / solve time | Logical rating result versus environment-dependent measurement. |
| Highest required strategy / last strategy used | Maximum strategy rank versus chronological position. |
| Clue-pattern symmetry / puzzle equivalence | Visual occupancy invariance versus transform-defined class membership. |
| Symmetry classification / symmetry randomization | Metadata about a clue pattern versus transforms used in generation. |
| Randomization / reveal | Equivalence-preserving presentation change versus addition of a clue. |
| Content mode / grid format | Information selected versus representation selected. |
| Stalled / unsolvable | Solver limitation versus a mathematical property of the puzzle. |
| Encoding / encryption | Representation versus secrecy. |

## Style and Naming Conventions

### Preferred prose

- Write **SudokuSolver** as one word with both `S` characters capitalized.
- Write **Sudoku** with an initial capital when referring to the puzzle type.
- Write **Canonical ID** in prose; use examples such as `17C-000001` in code
  style.
- Use **17-clue** with a hyphen when it modifies a noun: “17-clue puzzle” and
  “17-clue corpus.”
- Use **row-major** and **machine-readable** with hyphens when adjectival.
- Use the strategy registry as the authority for strategy names.
- Use exact lowercase, hyphenated values for persisted symmetry identifiers and
  CLI arguments.

### Preferred implementation names

Implementation languages may adapt names to their conventions, but a single
concept SHOULD retain a recognizable stem:

| Prose term | Suggested field or symbol |
| --- | --- |
| Canonical ID | `canonical_id` |
| Canonical puzzle string | `canonical_puzzle` |
| Fingerprint | `fingerprint` |
| Witness transform | `witness_transform` |
| Canonicalization version | `canonicalization_version` |
| Fingerprint format version | `fingerprint_version` |
| Corpus version | `corpus_version` |
| Rating version | `rating_version` |
| Generator version | `generator_version` |
| Clue count | `clue_count` |
| Difficulty label | `difficulty` or `difficulty_label` |
| Highest required strategy | `highest_strategy` |
| Clue-pattern symmetries | `symmetries` |
| Source collection | `source_collection` |
| Source ID | `source_id` |

Avoid multiple competing names such as `canon_id`, `puzzle_key`, and
`canonical_number` for the same concept.

## Short Definitions for Reuse

These compact definitions are approved for README files, CLI help, and other
places where the full definitions would be too long:

- **Puzzle:** An 81-cell Sudoku problem consisting of givens and empty cells.
- **Canonical puzzle:** The unique representative selected from a set of
  equivalent puzzles.
- **Fingerprint:** A deterministic, content-derived encoding of a canonical
  puzzle.
- **Canonical ID:** A stable, human-readable identifier assigned to a canonical
  corpus record.
- **Corpus:** The versioned collection of canonical puzzle records and the
  metadata needed to interpret them.
- **Witness transform:** The recorded transform mapping a source puzzle to its
  canonical representative.
- **Master file:** The authoritative serialized form of the definitive corpus.
- **Difficulty:** A classification assigned under a declared rating version.
- **Highest required strategy:** The most advanced strategy needed by a
  successful solve under a declared strategy ordering.
- **Clue-pattern symmetry:** Symmetry of occupied and empty cell positions,
  independent of digit values.
- **Generation provenance:** The inputs and ordered steps needed to audit and
  reproduce a generated puzzle.

## Governance

This guide is authoritative for project terminology. When another project
document uses a term differently, either that document should be corrected or
the exception should be stated explicitly.

Adding a persisted field, public API term, CLI option, or corpus concept SHOULD
include a corresponding review of this guide. A change to the meaning of an
identity, version, canonicalization, or corpus term may require a schema,
format, algorithm, or corpus version change.
