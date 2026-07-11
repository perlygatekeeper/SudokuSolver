#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::HiddenQuads;

sub values_left {
    my ($cell) = @_;
    return [ grep { $cell->possibilities->[$_] } 1 .. 9 ];
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my @quad = map { $grid->cell_from_row_column(0, $_) } (0, 2, 4, 6);

# Candidates 1, 3, 6, and 9 occur only in the four selected row cells.
for my $column (1, 3, 5, 7, 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    $cell->remove_possibility($_) for (1, 3, 6, 9);
}

my @deductions = Sudoku::Strategy::HiddenQuads->new->apply($grid);

is(
    scalar @deductions,
    20,
    'Hidden Quads removes five other candidates from each of four cells',
);

isa_ok($deductions[0], 'Sudoku::Deduction');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 20, 'all Hidden Quad deductions apply');

for my $cell (@quad) {
    is_deeply(
        values_left($cell),
        [1, 3, 6, 9],
        'Hidden Quad cell keeps only 1, 3, 6, and 9',
    );
}

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);

# Candidate 9 remains possible in five row cells, so 1/3/6/9 are not a Hidden Quad.
for my $column (1, 3, 5, 7) {
    my $cell = $invalid->cell_from_row_column(0, $column);
    $cell->remove_possibility($_) for (1, 3, 6, 9);
}
$invalid->cell_from_row_column(0, 8)->remove_possibility($_) for (1, 3, 6);

is(
    scalar(Sudoku::Strategy::HiddenQuads->new->apply($invalid)),
    0,
    'candidates spread across five cells do not form a Hidden Quad',
);

done_testing();
