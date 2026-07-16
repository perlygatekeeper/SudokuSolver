.PHONY: \
    all help check syntax test run clean status \
    deps deps-notest version gitadd perl-version \
    backup tarball report solved echo 17-50 benchmark benchmark-first50 benchmark-all-1000 examples corpus-audit canonical-benchmark canonical-index canonical-identities canonical-solutions

PERL          ?= perl5.34
PROVE         := prove
SCRIPT        := bin/sudoku.pl
SCRIPTS       := $(shell ls bin/*.pl)
MODS          := $(shell find lib -name '*.pm' | sort)
PUZZLE        := Puzzles/Puzzle3.txt
PUZZLEDIR     := Puzzles/
TAR           := gtar
NAME          := sudoku_solver
TESTDIR       := t/
THEMEDIR      := themes/
DOCSDIR       := docs/
RELEASE_NOTES := $(shell ls docs/Release_*.txt)
ROADMAP       := $(shell ls docs/Roadmap*.txt)
CPANFILE      := cpanfile
VERSION_MOD   := lib/Sudoku.pm

Puzzles = Puzzle_01 Puzzle_02 Puzzle_03 Puzzle_04 Puzzle_05 Puzzle_06 Puzzle_07 Puzzle_08 Puzzle_09 Puzzle_10 \
	  Puzzle_11 Puzzle_12 Puzzle_13 Puzzle_14 Puzzle_15 Puzzle_16 Puzzle_17 Puzzle_18 Puzzle_19 Puzzle_20 \
	  Puzzle_21 Puzzle_22 Puzzle_23 Puzzle_24 Puzzle_25 Puzzle_26 Puzzle_27 Puzzle_28 Puzzle_29 Puzzle_30 \
	  Puzzle_31 Puzzle_32 Puzzle_33 Puzzle_34 Puzzle_35 Puzzle_36 Puzzle_37 Puzzle_38 Puzzle_39 Puzzle_40 \
	  Puzzle_41 Puzzle_42 Puzzle_43 Puzzle_44 Puzzle_45 Puzzle_46 Puzzle_47 Puzzle_48 Puzzle_49 Puzzle_50

echo:
	@echo ${Puzzles}

all:
	for puzzle in $(Puzzles); do \
	  echo making $$puzzle; \
 	  ./bin/sudoku.pl $$puzzle > Puzzles/$${puzzle}_solution.txt || exit 1; \
	done

tidy:
	@find lib t bin -name '*.pm' -o -name '*.pl' -o -name '*.t' | \
	while read f; do \
	    perl -pi -e 's/[ \t]+$$//' "$$f"; \
	done

17-50:
	for puzzle in `countdown -f '%02d  ' 1 50`; do \
	  echo $$puzzle; \
	  ./bin/sudoku.pl "$$puzzle" > Puzzles/sudoku17_$${puzzle}_solution.txt || exit 1; \
	done

solved:
	@echo "solved:   \c"
	@tail -1 Puzzles/sudoku17_* | perl -lane "print if  m'\d{81}';"    | wc -l
	@echo "unsolved: \c"
	@tail -1 Puzzles/sudoku17_* | perl -lane "print if  m'\+------'; " | wc -l

report:
	@tail -1 Puzzles/sudoku17_* | perl -ape " s/ \<==\n/  /; s/==\> Puzzles\/sudoku17_//; s/_solution\.txt/  /; s/(\+\s*|\d)\n/$$1/; "
	@echo " "

help:
	@echo "SudokuSolver Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make check    - run syntax and tests"
	@echo "  make syntax   - perl -c main script and libraries"
	@echo "  make test     - run Perl tests with prove"
	@echo "  make run      - run solver"
	@echo "  make clean    - remove generated output files"
	@echo "  make status   - git status"
	@echo "  make deps     - install CPAN dependencies from cpanfile"
	@echo "  make version  - show project version"
	@echo "  make benchmark          - run canonical 17-clue benchmark"
	@echo "  make benchmark-all-1000 - benchmark every Puzzles/Benchmarks_Corpus/sudoku17-??-1000.txt file"
	@echo "  make examples     - run solved, stalled, contradiction, and output examples"
	@echo "  make corpus-audit       - validate coordinate encodings for all 49,158 canonical puzzles"
	@echo "  make canonical-benchmark - benchmark full canonization (LIMIT=50 by default)"
	@echo "  make canonical-index    - build deterministic canonical staging index (LIMIT/JOBS/OUTPUT supported)"
	@echo "  make canonical-identities - assign permanent IDs from canonical ordering (INPUT/OUTPUT supported)"
	@echo "  make canonical-solutions  - solve and validate permanent canonical identities (INPUT/OUTPUT/LIMIT supported)"
	@echo ""
	@echo "Variables:"
	@echo "  make run PUZZLE=Puzzles/Puzzle.txt"

check: syntax test

syntax:
	$(PERL) -Ilib -c $(SCRIPT)
	@for mod in $(MODS); do \
	  echo "Checking $$mod"; \
	  $(PERL) -Ilib -c $$mod || exit 1; \
	done

test:
	@if [ -d t ]; then \
		$(PROVE) -l t; \
	else \
		echo "No t/ directory yet; skipping tests."; \
	fi

deps:
	cpanm --installdeps .

deps-notest:
	cpanm --notest --installdeps .

benchmark: benchmark-first1000

benchmark-first50:
	@echo "== Canonical 17-Clue Benchmark (First 50) =="

benchmark-first100:
	@echo "== Canonical 17-Clue Benchmark (First 100) =="
	@$(PERL) -Ilib $(SCRIPT) --benchmark Puzzles/Benchmarks_Corpus/sudoku17-first100.txt

benchmark-first1000:
	@echo "== Canonical 17-Clue Benchmark (First 1000) =="
	@$(PERL) -Ilib $(SCRIPT) --benchmark Puzzles/Benchmarks_Corpus/sudoku17-first1000.txt


benchmark-all-1000:
	@set -e; \
	found=0; \
	for puzzle in Puzzles/Benchmarks_Corpus/sudoku17-??-1000.txt; do \
		[ -f "$$puzzle" ] || continue; \
		found=1; \
		report="$${puzzle%.txt}-benchmark.txt"; \
		tmp="$$report.tmp"; \
		echo "== Benchmarking $$puzzle =="; \
		if $(PERL) -Ilib $(SCRIPT) --benchmark "$$puzzle" | tee "$$tmp"; then \
			mv "$$tmp" "$$report"; \
			cat "$$report"; \
			echo "Report: $$report"; \
		else \
			status=$$?; \
			rm -f "$$tmp"; \
			exit $$status; \
		fi; \
		echo ""; \
	done; \
	if [ "$$found" -eq 0 ]; then \
		echo "No benchmark files matched Puzzles/Benchmarks_Corpus/sudoku17-??-1000.txt" >&2; \
		exit 1; \
	fi

benchmark-final4:
	@echo "== Canonical 17-Clue Benchmark (Final 4 Stalled Puzzles) =="
	@$(PERL) -Ilib $(SCRIPT) --benchmark Puzzles/Benchmarks_Corpus/sudoku17-final4.txt

corpus-audit:
	@$(PERL) -Ilib bin/audit-coordinate-encoding.pl

canonical-benchmark:
	@$(PERL) -Ilib bin/benchmark-canonicalization.pl --limit $${LIMIT:-50}

canonical-index:
	@$(PERL) -Ilib bin/build-canonical-index.pl \
		--limit $${LIMIT:-50} \
		--jobs $${JOBS:-1} \
		--output $${OUTPUT:-Puzzles/Benchmarks_Corpus/sudoku17-canonical-index.tsv}

canonical-identities:
	@$(PERL) -Ilib bin/build-canonical-identities.pl \
		--input $${INPUT:-Puzzles/Benchmarks_Corpus/sudoku17-canonical-index.tsv} \
		--output $${OUTPUT:-Puzzles/Benchmarks_Corpus/sudoku17-canonical-identities.tsv}

canonical-solutions:
	@$(PERL) -Ilib bin/build-canonical-solutions.pl \
		--input $${INPUT:-Puzzles/Benchmarks_Corpus/sudoku17-canonical-identities.tsv} \
		--output $${OUTPUT:-Puzzles/Benchmarks_Corpus/sudoku17-canonical-solutions.tsv} \
		--limit $${LIMIT:-0}

examples:
	@mkdir -p examples-output
	@echo "== Solved example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output normal
	@echo ""
	@echo "== Stalled example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/stalled.sdk --output normal
	@echo ""
	@echo "== Contradiction example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/contradiction.sdk --output normal
	@echo ""
	@echo "== Compact and mixed-weight Unicode grids =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format compact
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format pretty --character-set UNICODE_MIXED
	@echo ""
	@echo "== Machine-readable results =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --result-format json --output-file examples-output/solved.json
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --result-format csv --output-file examples-output/solved.csv
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --result-format tsv --output-file examples-output/solved.tsv
	@echo "== Document and image renderers =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format markdown --output-file examples-output/solved.md
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format html --output-file examples-output/solved.html
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format svg --output-file examples-output/solved.svg
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format png --output-file examples-output/solved.png
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output quiet --grid-format pdf --output-file examples-output/solved.pdf
	@echo "Generated examples in examples-output/"

run:
	$(PERL) -Ilib $(SCRIPT) $(PUZZLE)

clean:
	rm -f *.out *.solution
	rm -f Puzzle*.out Puzzle*.solution
	rm -f Puzzles/*.out Puzzles/*.solution
	rm -f sudoku_solver*.tgz
	rm -rf examples-output
	find . -name '*~' -delete
	find . -name '*.bak' -delete
	find . -name '.DS_Store' -delete

status:
	git status --short

show-compact:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format compact \
		--file Puzzles/solved_puzzle.txt

show-pretty:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format pretty \
		--file Puzzles/solved_puzzle.txt

show-unicode:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format pretty \
		--character-set UNICODE_LIGHT \
		--file Puzzles/solved_puzzle.txt

show-unicode-double:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format pretty \
		--character-set UNICODE_DOUBLE \
		--file Puzzles/solved_puzzle.txt

show-unicode-heavy:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format pretty \
		--character-set UNICODE_HEAVY \
		--file Puzzles/solved_puzzle.txt

show-candidates:
	perl -Ilib bin/sudoku.pl \
		--output quiet \
		--grid-format candidates \
		--file Puzzles/solved_puzzle.txt

tarball: backup

backup:
	$(TAR) -cvzf ./$(NAME)-`date +%Y%m%d-%H%M`.tgz \
		Makefile \
		Readme.md \
		$(SCRIPTS) \
		$(MODS) \
		$(THEMESDIR) \
		$(TESTDIR)*.t \
		$(DOCSDIR)*.txt \
		$(DOCSDIR)Developer/*.md \
		$(DOCSDIR)benchmark_*.txt \
		$(DOCSDIR)Algorithm_Notes/*.md \
		$(DOCSDIR)Strategies/*.md \
		$(PUZZLEDIR)Examples/*.sdk \
		$(PUZZLEDIR)Benchmarks_Corpus/*.txt \
		$(PUZZLEDIR)*.txt \
		$(CPANFILE)

version:
	@$(PERL) -Ilib -MSudoku -e 'print "SudokuSolver $$Sudoku::VERSION\n"'

gitadd:
	git add Makefile Readme.md \
		$(SCRIPTS) $(MODS) $(VERSION_MOD) \
		$(THEMEDIR)*.theme $(TESTDIR)*.t $(DOCSDIR)*.txt \
		$(DOCSDIR)Developer/*.md \
		$(DOCSDIR)benchmark_*.txt \
		$(DOCSDIR)Algorithm_Notes/*.md \
		$(DOCSDIR)Strategies/*.md \
		$(PUZZLEDIR)Examples/*.sdk \
		$(PUZZLEDIR)Benchmarks_Corpus/*.txt \
		$(PUZZLEDIR)*.txt $(CPANFILE)
	git status

perl-version:
	$(PERL) -v

size:
	@echo "Project size, non-blank lines"
	@echo "============================="
	        @printf "%-28s %8s\n" "Component" "Lines"
	@printf "%-28s %8s\n" "---------" "-----"
	@printf "%-28s %8s\n" "bin/sudoku.pl" "$$(grep -hcv '^[[:space:]]*$$' bin/sudoku.pl 2>/dev/null || echo 0)"
	@printf "%-28s %8s\n" "lib" "$$(find lib -type f -name '*.pm' -print0 | xargs -0 grep -hcv '^[[:space:]]*$$' | awk '{s+=$$1} END {print s+0}')"
	@printf "%-28s %8s\n" "tests" "$$(find t -type f -name '*.t' -print0 | xargs -0 grep -hcv '^[[:space:]]*$$' | awk '{s+=$$1} END {print s+0}')"
	@printf "%-28s %8s\n" "docs" "$$(find docs -type f -print0 | xargs -0 grep -hcv '^[[:space:]]*$$' | awk '{s+=$$1} END {print s+0}')"
	@printf "%-28s %8s\n" "Puzzles" "$$(find Puzzles -type f -print0 | xargs -0 grep -hcv '^[[:space:]]*$$' | awk '{s+=$$1} END {print s+0}')"
	@echo "-----------------------------"
	@printf "%-28s %8s\n" "TOTAL" "$$(find bin/sudoku.pl lib t Puzzles -type f \( -name '*.pl' -o -name '*.pm' -o -name '*.t' -o -name '*.txt' \) -print0 | xargs -0 grep -hcv '^[[:space:]]*$$' | awk '{s+=$$1} END {print s+0}')"


size-modules:
	@echo "Module size, non-blank lines"
	@echo "============================"
