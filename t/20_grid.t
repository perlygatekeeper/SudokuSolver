#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;

my $puzzle_string = '003020600900305001001806400008102900700000008006708200002609500800203009005010300';
my $given_count   = () = $puzzle_string =~ /[1-9]/g;

my $grid = Grid->new;
$grid->load_from_string($puzzle_string);

is(scalar @{ $grid->cells }, 81, 'load_from_string creates 81 cells');
is($grid->solved, $given_count, 'solved count begins as the number of given clues');

is_deeply(
    [ map { scalar @{$_} } @{ $grid->rows } ],
    [ (9) x 9 ],
    'grid has nine rows with nine cells each',
);

is_deeply(
    [ map { scalar @{$_} } @{ $grid->columns } ],
    [ (9) x 9 ],
    'grid has nine columns with nine cells each',
);

is_deeply(
    [ map { scalar @{$_} } @{ $grid->boxes } ],
    [ (9) x 9 ],
    'grid has nine boxes with nine cells each',
);

my $r1c1 = $grid->cell_from_row_column(0, 0);
is($r1c1->row, 0, 'cell stores zero-based row');
is($r1c1->column, 0, 'cell stores zero-based column');
is($r1c1->box, 0, 'cell stores zero-based box');
is($r1c1->value, 0, 'blank cells are unsolved');
is($r1c1->given, 0, 'blank cells are not givens');

my $r1c3 = $grid->cell_from_row_column(0, 2);
is($r1c3->value, 3, 'given digit is loaded into the expected cell');
is($r1c3->given, 1, 'given digit cell is marked as given');
is($grid->cells->[2], $r1c3, 'cell_from_row_column returns the same object stored in cells');

is(scalar @{ $grid->row_mates_of($r1c3) }, 8, 'row_mates_of returns eight cells');
is(scalar @{ $grid->column_mates_of($r1c3) }, 8, 'column_mates_of returns eight cells');
is(scalar @{ $grid->box_mates_of($r1c3) }, 8, 'box_mates_of returns eight cells');

ok(!$r1c1->possibilities->[3], 'given values are removed from row mates during load');

is(scalar @{ $grid->solved_cells }, $given_count, 'solved_cells returns the given cells after load');
is(scalar @{ $grid->unsolved_cells }, 81 - $given_count, 'unsolved_cells returns the remaining cells after load');

done_testing();
