#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;

sub coords_of {
    return [ sort map { $_->row . ',' . $_->column } @_ ];
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $center = $grid->cell_from_row_column(4, 4);

is($center->box, 4, 'center cell is in the center box');

my $row_mates = $grid->row_mates_of($center);
is(scalar @{$row_mates}, 8, 'row_mates_of returns eight cells');
ok(
    !(grep { $_ == $center } @{$row_mates}),
    'row_mates_of does not include the original cell',
);
is_deeply(
    coords_of(@{$row_mates}),
    coords_of(map { $grid->cell_from_row_column(4, $_) } grep { $_ != 4 } 0 .. 8),
    'row_mates_of returns all other cells in the row',
);

my $column_mates = $grid->column_mates_of($center);
is(scalar @{$column_mates}, 8, 'column_mates_of returns eight cells');
ok(
    !(grep { $_ == $center } @{$column_mates}),
    'column_mates_of does not include the original cell',
);

is_deeply(
    coords_of(@{$column_mates}),
    coords_of(map { $grid->cell_from_row_column($_, 4) } grep { $_ != 4 } 0 .. 8),
    'column_mates_of returns all other cells in the column',
);

my $box_mates = $grid->box_mates_of($center);
is(scalar @{$box_mates}, 8, 'box_mates_of returns eight cells');
ok(
    !(grep { $_ == $center } @{$box_mates}),
    'box_mates_of does not include the original cell',
);
is_deeply(
    coords_of(@{$box_mates}),
    coords_of(
        map { $grid->cell_from_row_column($_->[0], $_->[1]) }
        grep { $_->[0] != 4 || $_->[1] != 4 }
        map { my $row = $_; map { [ $row, $_ ] } 3 .. 5 } 3 .. 5
    ),
    'box_mates_of returns all other cells in the box',
);

my $same_row_intersections = $grid->intersections(
    $grid->cell_from_row_column(0, 0),
    $grid->cell_from_row_column(0, 4),
);
is(scalar @{$same_row_intersections}, 7, 'same-row intersections return the other cells in that row');
is_deeply(
    coords_of(@{$same_row_intersections}),
    coords_of(map { $grid->cell_from_row_column(0, $_) } grep { $_ != 0 && $_ != 4 } 0 .. 8),
    'same-row intersections exclude both original cells',
);

my $same_box_intersections = $grid->intersections(
    $grid->cell_from_row_column(0, 0),
    $grid->cell_from_row_column(1, 1),
);
is_deeply(
    coords_of(@{$same_box_intersections}),
    coords_of(
        $grid->cell_from_row_column(0, 2),
        $grid->cell_from_row_column(2, 0),
        $grid->cell_from_row_column(2, 2),
    ),
    'same-box diagonal intersections return the other box cells sharing neither row nor column with the second cell',
);

my $diagonal_intersections = $grid->intersections(
    $grid->cell_from_row_column(0, 0),
    $grid->cell_from_row_column(4, 4),
);
is_deeply(
    coords_of(@{$diagonal_intersections}),
    coords_of(
        $grid->cell_from_row_column(0, 4),
        $grid->cell_from_row_column(4, 0),
    ),
    'unrelated diagonal cells intersect at the two opposite corners of the rectangle',
);

done_testing();
