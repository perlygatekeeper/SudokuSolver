#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::NakedQuads;

sub set_possibilities {
    my ($cell, @values) = @_;

    my %keep = map { $_ => 1 } @values;
    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my @quad = (
    set_possibilities($grid->cell_from_row_column(0, 0), 1, 2),
    set_possibilities($grid->cell_from_row_column(0, 2), 2, 3),
    set_possibilities($grid->cell_from_row_column(0, 4), 3, 4),
    set_possibilities($grid->cell_from_row_column(0, 6), 1, 4),
);

my @deductions = Sudoku::Strategy::NakedQuads->new->apply($grid);

is(
    scalar @deductions,
    20,
    'Naked Quads removes four candidates from each of five other row cells',
);

isa_ok($deductions[0], 'Sudoku::Deduction');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 20, 'all Naked Quad deductions apply');

for my $cell (@quad) {
    my @left = grep { $cell->possibilities->[$_] } 1 .. 9;
    ok(@left == 2, 'each Naked Quad cell keeps its two candidates');
}

for my $column (1, 3, 5, 7, 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    for my $value (1 .. 4) {
        ok(
            !$cell->possibilities->[$value],
            "candidate $value removed from R1C" . ($column + 1),
        );
    }
}

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);
set_possibilities($invalid->cell_from_row_column(0, 0), 1, 2);
set_possibilities($invalid->cell_from_row_column(0, 2), 2, 3);
set_possibilities($invalid->cell_from_row_column(0, 4), 3, 4);
set_possibilities($invalid->cell_from_row_column(0, 6), 4, 5);

is(
    scalar(Sudoku::Strategy::NakedQuads->new->apply($invalid)),
    0,
    'four cells spanning five candidates do not form a Naked Quad',
);

done_testing();
