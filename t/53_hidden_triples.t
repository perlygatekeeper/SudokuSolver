#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::HiddenTriples;

sub values_left {
    my ($cell) = @_;
    return [ grep { $cell->possibilities->[$_] } 1 .. 9 ];
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my @triple = map { $grid->cell_from_row_column(0, $_) } (0, 3, 6);

# Candidates 2, 5, and 8 occur only in the three selected row cells.
for my $column (1, 2, 4, 5, 7, 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    $cell->remove_possibility($_) for (2, 5, 8);
}

my @deductions = Sudoku::Strategy::HiddenTriples->new->apply($grid);

is(
    scalar @deductions,
    18,
    'Hidden Triples removes six other candidates from each of three cells',
);

isa_ok($deductions[0], 'Sudoku::Deduction');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 18, 'all Hidden Triple deductions apply');

for my $cell (@triple) {
    is_deeply(
        values_left($cell),
        [2, 5, 8],
        'Hidden Triple cell keeps only 2, 5, and 8',
    );
}

for my $column (1, 2, 4, 5, 7, 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok(!$cell->possibilities->[2], "candidate 2 remains absent from R1C" . ($column + 1));
    ok(!$cell->possibilities->[5], "candidate 5 remains absent from R1C" . ($column + 1));
    ok(!$cell->possibilities->[8], "candidate 8 remains absent from R1C" . ($column + 1));
}

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);

# Candidate 8 remains possible in four row cells, so 2/5/8 are not a hidden triple.
for my $column (1, 2, 4, 5, 7) {
    my $cell = $invalid->cell_from_row_column(0, $column);
    $cell->remove_possibility($_) for (2, 5, 8);
}
$invalid->cell_from_row_column(0, 8)->remove_possibility($_) for (2, 5);

is(
    scalar(Sudoku::Strategy::HiddenTriples->new->apply($invalid)),
    0,
    'candidates spread across four cells do not form a Hidden Triple',
);

done_testing();
