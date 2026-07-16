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
