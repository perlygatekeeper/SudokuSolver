.PHONY: \
    all help check syntax test run clean status \
    deps deps-notest version gitadd perl-version \
    backup tarball report solved echo 17-50 benchmark benchmark-first50 examples

PERL          ?= perl5.34
PROVE         := prove
SCRIPT        := bin/sudoku.pl
MODS          := $(shell find lib -name '*.pm' | sort)
PUZZLE        := Puzzles/Puzzle3.txt
PUZZLEDIR     := Puzzles/
TAR           := gtar
NAME          := sudoku_solver
TESTDIR       := t/
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
	@echo "  make benchmark - run canonical 17-clue benchmark"
	@echo "  make examples  - run solved, stalled, and contradiction examples"
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
	@$(PERL) -Ilib $(SCRIPT) --benchmark Puzzles/sudoku17-first100.txt

benchmark-first1000:
	@echo "== Canonical 17-Clue Benchmark (First 1000) =="
	@$(PERL) -Ilib $(SCRIPT) --benchmark Puzzles/sudoku17-first1000.txt

examples:
	@echo "== Solved example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/solved.sdk --output normal
	@echo ""
	@echo "== Stalled example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/stalled.sdk --output normal
	@echo ""
	@echo "== Contradiction example =="
	@$(PERL) -Ilib $(SCRIPT) --file Puzzles/Examples/contradiction.sdk --output normal

run:
	$(PERL) -Ilib $(SCRIPT) $(PUZZLE)

clean:
	rm -f *.out *.solution
	rm -f Puzzle*.out Puzzle*.solution
	rm -f Puzzles/*.out Puzzles/*.solution
	find . -name '*~' -delete
	find . -name '*.bak' -delete
	find . -name '.DS_Store' -delete

status:
	git status --short

tarball: backup

backup:
	$(TAR) -cvzf ../$(NAME)-`date +%Y%m%d-%H%M`.tgz \
		Makefile \
		Readme.md \
		$(SCRIPT) \
		$(MODS) \
		$(TESTDIR)*.t \
		$(DOCSDIR)*.txt \
		$(DOCSDIR)Developer/*.md \
		$(DOCSDIR)benchmark_*.txt \
		$(DOCSDIR)Algorithm_Notes/*.md \
		$(DOCSDIR)Strategies/*.md \
		$(PUZZLEDIR)Examples/*.sdk \
		$(PUZZLEDIR)*.txt \
		$(CPANFILE)

version:
	@$(PERL) -Ilib -MSudoku -e 'print "SudokuSolver $$Sudoku::VERSION\n"'

gitadd:
	git add Makefile Readme.md \
		$(SCRIPT) $(MODS) $(VERSION_MOD) \
		$(TESTDIR)*.t $(DOCSDIR)*.txt \
		$(DOCSDIR)Developer/*.md \
		$(DOCSDIR)benchmark_*.txt \
		$(DOCSDIR)Algorithm_Notes/*.md \
		$(DOCSDIR)Strategies/*.md \
		$(PUZZLEDIR)Examples/*.sdk \
		$(PUZZLEDIR)*.txt $(CPANFILE)
	git status

perl-version:
	$(PERL) -v

size:
	@echo "Project size, non-blank lines"
	@echo "============================="

size-modules:
	@echo "Module size, non-blank lines"
	@echo "============================"
