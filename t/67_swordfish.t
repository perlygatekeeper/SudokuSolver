#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::Swordfish;

sub remove_candidate_except {
    my ( $grid, $orientation, $base_index, $value, @keep ) = @_;

    my %keep = map { ($_ => 1) } @keep;

    for my $cover_index (0 .. 8) {
        next if $keep{$cover_index};

        my $cell = $orientation eq 'row'
            ? $grid->cell_from_row_column($base_index, $cover_index)
            : $grid->cell_from_row_column($cover_index, $base_index);

        $cell->remove_possibility($value);
    }
}

my $strategy = Sudoku::Strategy::Swordfish->new;
is($strategy->name, 'Swordfish', 'strategy reports canonical name');

my $row_grid = Grid->new;
$row_grid->load_from_string('.' x 81);

remove_candidate_except($row_grid, 'row', 0, 5, 1, 4);
remove_candidate_except($row_grid, 'row', 3, 5, 4, 7);
remove_candidate_except($row_grid, 'row', 6, 5, 1, 7);

my @row_deductions = $strategy->apply($row_grid);
is(scalar @row_deductions, 18, 'row-based Swordfish finds eighteen eliminations');
isa_ok($row_deductions[0], 'Sudoku::Deduction');
is($row_deductions[0]->strategy, 'Swordfish', 'deduction records strategy');
is($row_deductions[0]->action, 'remove_candidate', 'deduction removes a candidate');
is($row_deductions[0]->value, 5, 'deduction records fish candidate');
like($row_deductions[0]->reason, qr/rows 1, 4, 7/, 'reason identifies base rows');
like($row_deductions[0]->reason, qr/columns 2, 5, 8/, 'reason identifies cover columns');

is($row_grid->apply_deductions(@row_deductions), 18, 'row-based deductions apply');

for my $row (1, 2, 4, 5, 7, 8) {
    for my $column (1, 4, 7) {
        ok(!$row_grid->cell_from_row_column($row, $column)->possibilities->[5],
            "candidate removed from R" . ($row + 1) . 'C' . ($column + 1));
    }
}

my $column_grid = Grid->new;
$column_grid->load_from_string('.' x 81);

remove_candidate_except($column_grid, 'column', 0, 6, 2, 5);
remove_candidate_except($column_grid, 'column', 4, 6, 5, 8);
remove_candidate_except($column_grid, 'column', 7, 6, 2, 8);

my @column_deductions = $strategy->apply($column_grid);
is(scalar @column_deductions, 18, 'column-based Swordfish finds eighteen eliminations');
like($column_deductions[0]->reason, qr/columns 1, 5, 8/, 'reason identifies base columns');
like($column_deductions[0]->reason, qr/rows 3, 6, 9/, 'reason identifies cover rows');

my $negative_grid = Grid->new;
$negative_grid->load_from_string('.' x 81);

remove_candidate_except($negative_grid, 'row', 0, 7, 1, 4);
remove_candidate_except($negative_grid, 'row', 3, 7, 4, 7);
remove_candidate_except($negative_grid, 'row', 6, 7, 1, 8);

my @negative = $strategy->apply($negative_grid);
is(scalar @negative, 0, 'four cover columns do not form a Swordfish');

done_testing();
