#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;

my $puzzle = '1' . ('.' x 80);

my $grid = Grid->new;
$grid->load_from_string($puzzle);

is(scalar @{ $grid->cells }, 81, 'load_from_string creates exactly 81 cells');
is($grid->solved, 1, 'load_from_string counts given cells as solved');

my $first = $grid->cell_from_row_column(0, 0);
is($first->value, 1, 'first clue is loaded as a given value');
is($first->given, 1, 'first clue is marked as a given');

my $second = $grid->cell_from_row_column(0, 1);
is($second->value, 0, 'non-digit clue is loaded as an unsolved cell');
is($second->given, 0, 'non-digit clue is not marked as a given');

ok(!$grid->cell_from_row_column(0, 1)->possibilities->[1], 'given value is removed from row mates');
ok(!$grid->cell_from_row_column(1, 0)->possibilities->[1], 'given value is removed from column mates');
ok(!$grid->cell_from_row_column(1, 1)->possibilities->[1], 'given value is removed from box mates');
ok($grid->cell_from_row_column(8, 8)->possibilities->[1], 'given value remains possible in non-mate cells');

my @index_expectations = (
    [  0, 0, 0, 0 ],
    [  8, 0, 8, 2 ],
    [  9, 1, 0, 0 ],
    [ 10, 1, 1, 0 ],
    [ 40, 4, 4, 4 ],
    [ 80, 8, 8, 8 ],
);

for my $case (@index_expectations) {
    my ($index, $row, $column, $box) = @{$case};
    my $cell = $grid->cells->[$index];

    is($cell->row,    $row,    "cell $index has expected row");
    is($cell->column, $column, "cell $index has expected column");
    is($cell->box,    $box,    "cell $index has expected box");
}

$grid->load_from_string('.' x 81);

is(scalar @{ $grid->cells }, 81, 'load_from_string resets the cell list on reload');
is($grid->solved, 0, 'load_from_string resets solved count on reload');
is(scalar @{ $grid->solved_cells }, 0, 'reload with no givens leaves no solved cells');
is(scalar @{ $grid->unsolved_cells }, 81, 'reload with no givens leaves all cells unsolved');

done_testing();
