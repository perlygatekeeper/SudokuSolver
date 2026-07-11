#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::NakedTriples;

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

my @triple = (
    set_possibilities($grid->cell_from_row_column(0, 0), 1, 2),
    set_possibilities($grid->cell_from_row_column(0, 3), 1, 3),
    set_possibilities($grid->cell_from_row_column(0, 6), 2, 3),
);

my @deductions = Sudoku::Strategy::NakedTriples->new->apply($grid);

is(
    scalar @deductions,
    18,
    'Naked Triples removes three candidates from each of six other row cells',
);

isa_ok($deductions[0], 'Sudoku::Deduction');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 18, 'all Naked Triple deductions apply');

for my $cell (@triple) {
    my @left = grep { $cell->possibilities->[$_] } 1 .. 9;
    ok(@left == 2, 'each Naked Triple cell keeps its two candidates');
}

for my $column (1, 2, 4, 5, 7, 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok(!$cell->possibilities->[1], "candidate 1 removed from R1C" . ($column + 1));
    ok(!$cell->possibilities->[2], "candidate 2 removed from R1C" . ($column + 1));
    ok(!$cell->possibilities->[3], "candidate 3 removed from R1C" . ($column + 1));
}

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);
set_possibilities($invalid->cell_from_row_column(0, 0), 1, 2);
set_possibilities($invalid->cell_from_row_column(0, 3), 1, 3);
set_possibilities($invalid->cell_from_row_column(0, 6), 2, 4);

is(
    scalar(Sudoku::Strategy::NakedTriples->new->apply($invalid)),
    0,
    'three cells spanning four candidates do not form a Naked Triple',
);

done_testing();
