#!/usr/bin/env bash
set -euo pipefail

# Renumber the SudokuSolver test suite into stable three-digit functional ranges.
#
# Preview only (default):
#   bash tools/maintenance/renumber-sudoku-tests-merged.sh
#
# Apply from the SudokuSolver repository root:
#   bash tools/maintenance/renumber-sudoku-tests-merged.sh --apply

MODE="preview"
case "${1:-}" in
    "") ;;
    --apply) MODE="apply" ;;
    *)
        printf 'Usage: %s [--apply]\n' "$0" >&2
        exit 2
        ;;
esac

if [[ ! -d .git || ! -d t || ! -d docs ]]; then
    printf 'Error: run this script from the SudokuSolver repository root.\n' >&2
    exit 1
fi

# Refuse to mix the mechanical rename with existing tracked changes.
if ! git diff --quiet || ! git diff --cached --quiet; then
    printf 'Error: tracked working-tree or index changes exist. Commit or stash them first.\n' >&2
    exit 1
fi

# Functional ranges:
#   000-099  loading, Cell, Grid
#   100-199  solver core and deduction infrastructure
#   200-299  singles, intersections, subsets
#   300-399  fish, wings, uniqueness
#   400-499  chains, coloring, AIC
#   500-599  hypothetical and forcing inference
#   600-699  statistics, modes, benchmark
#   700-799  rendering and output
#   900-999  regression tests

RENAMES=$(cat <<'MAP'
00_load.t|000_load.t
10_cell.t|010_cell.t
11_cell_validation.t|011_cell_validation.t
12_cell_output.t|012_cell_output.t
20_grid.t|020_grid.t
21_grid_load.t|021_grid_load.t
22_grid_units.t|022_grid_units.t
23_grid_output.t|023_grid_output.t
30_solver_input.t|100_solver_input.t
30_solver_options.t|101_solver_options.t
31_solver_api.t|110_solver_api.t
32_solver_execution.t|111_solver_execution.t
33_deduction.t|120_deduction.t
34_solver_deduction_log.t|121_solver_deduction_log.t
35_solver_apply_deduction.t|122_solver_apply_deduction.t
36_strategy_registry.t|130_strategy_registry.t
37_solver_run_strategy.t|131_solver_run_strategy.t
38_solver_strategy_restart.t|132_solver_strategy_restart.t
39_strategy_contract.t|133_strategy_contract.t
40_naked_singles.t|200_naked_singles.t
41_hidden_singles.t|201_hidden_singles.t
42_pointing_claiming.t|210_pointing_claiming.t
50_naked_pairs.t|220_naked_pairs.t
51_hidden_pairs.t|221_hidden_pairs.t
52_naked_triples.t|222_naked_triples.t
53_hidden_triples.t|223_hidden_triples.t
54_naked_quads.t|224_naked_quads.t
55_hidden_quads.t|225_hidden_quads.t
60_x_wings.t|300_x_wings.t
67_swordfish.t|301_swordfish.t
67_jellyfish.t|302_jellyfish.t
62_xy_wing.t|310_xy_wing.t
63_xyz_wing.t|311_xyz_wing.t
64_wxyz_wing.t|312_wxyz_wing.t
65_unique_rectangle_type1.t|320_unique_rectangle_type1.t
66_unique_rectangle_type2.t|321_unique_rectangle_type2.t
65_unique_rectangle_type3.t|322_unique_rectangle_type3.t
65_unique_rectangle_type4.t|323_unique_rectangle_type4.t
61_remote_pairs.t|400_remote_pairs.t
68_skyscraper.t|410_skyscraper.t
69_two_string_kite.t|411_two_string_kite.t
69_simple_coloring.t|420_simple_coloring.t
69_multi_coloring.t|421_multi_coloring.t
69_x_chains.t|430_x_chains.t
69_xy_chains.t|431_xy_chains.t
69_grouped_l1_wing.t|440_grouped_l1_wing.t
69_aic.t|450_aic.t
69_grouped_aic.t|451_grouped_aic.t
70_hypothetical.t|500_hypothetical.t
71_digit_forcing_chains.t|510_digit_forcing_chains.t
70_statistics.t|600_statistics.t
71_step_by_step.t|610_step_by_step.t
72_contradiction_detection.t|611_contradiction_detection.t
73_hint_mode.t|620_hint_mode.t
74_explain_mode.t|621_explain_mode.t
75_difficulty_rating.t|630_difficulty_rating.t
76_benchmark.t|640_benchmark.t
76_grid_builder.t|700_grid_builder.t
77_grid_character_sets.t|701_grid_character_sets.t
78_text_renderer.t|710_text_renderer.t
78_compact_grid_renderer.t|711_compact_grid_renderer.t
78_pretty_grid_renderer.t|712_pretty_grid_renderer.t
78_candidate_grid_renderer.t|713_candidate_grid_renderer.t
78_candidate_line_renderer.t|714_candidate_line_renderer.t
78_candidate_list_renderer.t|715_candidate_list_renderer.t
78_candidate_json_renderer.t|716_candidate_json_renderer.t
78_result_json_renderer.t|717_result_json_renderer.t
78_grid_format_registry.t|720_grid_format_registry.t
78_renderer_events.t|721_renderer_events.t
79_solver_events.t|722_solver_events.t
79_output_modes.t|730_output_modes.t
79_output_file.t|731_output_file.t
90_regression_known_solution.t|900_regression_known_solution.t
MAP
)

# Explicit references found in the merged tree. The three aliases below correct
# stale strategy-document names that no longer match existing tests.
DOC_EDITS=$(cat <<'EDITS'
docs/Developer/Architecture.md|t/39_strategy_contract.t|t/133_strategy_contract.t
docs/Strategies/NakedSingles.md|t/40_singletons.t|t/200_naked_singles.t
docs/Strategies/HiddenSingles.md|t/41_lone_representatives.t|t/201_hidden_singles.t
docs/Strategies/PointingClaiming.md|t/42_imaginary_values.t|t/210_pointing_claiming.t
docs/Strategies/NakedPairs.md|t/50_naked_pairs.t|t/220_naked_pairs.t
docs/Strategies/HiddenPairs.md|t/51_hidden_pairs.t|t/221_hidden_pairs.t
docs/Strategies/NakedTriples.md|t/52_naked_triples.t|t/222_naked_triples.t
docs/Strategies/HiddenTriples.md|t/53_hidden_triples.t|t/223_hidden_triples.t
docs/Strategies/NakedQuads.md|t/54_naked_quads.t|t/224_naked_quads.t
docs/Strategies/HiddenQuads.md|t/55_hidden_quads.t|t/225_hidden_quads.t
docs/Strategies/XWings.md|t/60_x_wings.t|t/300_x_wings.t
docs/Strategies/RemotePairs.md|t/61_remote_pairs.t|t/400_remote_pairs.t
t/71_digit_forcing_chains.t|t/70_hypothetical.t|t/500_hypothetical.t
Puzzles/Examples/solved.sdk|t/90_regression_known_solution.t|t/900_regression_known_solution.t
EDITS
)

validate_renames() {
    local old new
    local count=0

    while IFS='|' read -r old new; do
        [[ -n "$old" ]] || continue
        ((count += 1))

        if [[ ! -f "t/$old" ]]; then
            printf 'Error: expected source test is missing: t/%s\n' "$old" >&2
            exit 1
        fi

        if [[ -e "t/$new" ]]; then
            printf 'Error: destination already exists: t/%s\n' "$new" >&2
            exit 1
        fi
    done <<< "$RENAMES"

    local actual
    actual=$(find t -maxdepth 1 -type f -name '*.t' | wc -l | tr -d ' ')
    if [[ "$count" -ne "$actual" ]]; then
        printf 'Error: mapping covers %d tests, but the tree contains %d.\n' "$count" "$actual" >&2
        printf 'The suite changed after this script was generated; update the mapping first.\n' >&2
        exit 1
    fi
}

validate_doc_edits() {
    local file old new
    while IFS='|' read -r file old new; do
        [[ -n "$file" ]] || continue
        if [[ ! -f "$file" ]]; then
            printf 'Error: referenced file is missing: %s\n' "$file" >&2
            exit 1
        fi
        if ! grep -Fq -- "$old" "$file"; then
            printf 'Error: expected reference not found in %s: %s\n' "$file" "$old" >&2
            exit 1
        fi
    done <<< "$DOC_EDITS"
}

print_preview() {
    local old new file before after

    printf 'Proposed test renames (%s files):\n\n' \
        "$(printf '%s\n' "$RENAMES" | grep -c '|')"
    while IFS='|' read -r old new; do
        [[ -n "$old" ]] || continue
        printf 'git mv %-43s %s\n' "t/$old" "t/$new"
    done <<< "$RENAMES"

    printf '\nProposed reference edits:\n\n'
    while IFS='|' read -r file before after; do
        [[ -n "$file" ]] || continue
        printf '%s\n    %s\n -> %s\n' "$file" "$before" "$after"
    done <<< "$DOC_EDITS"

    printf '\nNo files were changed. Re-run with --apply after review.\n'
}

apply_doc_edits() {
    # Pass the explicit edit table to Python to avoid platform-specific sed -i
    # behavior between macOS and GNU systems.
    DOC_EDITS_DATA="$DOC_EDITS" python3 <<'PY'
import os
from pathlib import Path

for line in os.environ["DOC_EDITS_DATA"].splitlines():
    if not line:
        continue
    filename, old, new = line.split("|", 2)
    path = Path(filename)
    text = path.read_text(encoding="utf-8")
    count = text.count(old)
    if count == 0:
        raise SystemExit(f"expected reference disappeared from {filename}: {old}")
    path.write_text(text.replace(old, new), encoding="utf-8")
    print(f"updated {filename}: {old} -> {new} ({count} occurrence(s))")
PY
}

validate_renames
validate_doc_edits

if [[ "$MODE" == "preview" ]]; then
    print_preview
    exit 0
fi

printf 'Updating documentation and internal references...\n'
apply_doc_edits

printf '\nRenaming tests...\n'
while IFS='|' read -r old new; do
    [[ -n "$old" ]] || continue
    git mv "t/$old" "t/$new"
done <<< "$RENAMES"

printf '\nChecking for stale numbered test references...\n'
if git grep -nE 't/[0-9]{2}_[A-Za-z0-9_]+\.t' -- . ':!docs/Release*' ':!docs/benchmark*'; then
    printf '\nWarning: two-digit test references remain above. Review them manually.\n' >&2
else
    printf 'No two-digit test references remain in tracked files.\n'
fi

printf '\nRenumbering complete. Review with:\n\n'
printf '    git status --short\n'
printf '    git diff --stat\n'
printf '    git diff -- docs t Puzzles/Examples/solved.sdk\n'
printf '    make PERL=perl check\n'
printf '    git diff --check\n\n'
printf 'Suggested commit message:\n\n'
printf '    Reorganize test suite with three-digit numbering\n'
