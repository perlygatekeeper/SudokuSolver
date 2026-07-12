#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::UniqueRectangleType1;

sub set_possibilities {
    my ($cell, @values) = @_;

    my %keep = map { ($_ => 1) } @values;
    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

sub deduction_for {
    my ($deductions, $cell, $value) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $value
    } @{$deductions};
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $a = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2);
my $b = set_possibilities($grid->cell_from_row_column(0, 3), 1, 2);
my $c = set_possibilities($grid->cell_from_row_column(1, 0), 1, 2);
my $roof = set_possibilities($grid->cell_from_row_column(1, 3), 1, 2, 3);

my @deductions = Sudoku::Strategy::UniqueRectangleType1->new->apply($grid);

is(deduction_for(\@deductions, $roof, 1), 1,
    'Type 1 removes the first deadly-pair candidate from the roof');
is(deduction_for(\@deductions, $roof, 2), 1,
    'Type 1 removes the second deadly-pair candidate from the roof');
is(scalar @deductions, 2, 'the fixture produces exactly two deductions');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/unique solution/i,
    'deduction states the uniqueness assumption');
like($deductions[0]->reason, qr/deadly rectangle/i,
    'deduction explains the deadly rectangle');

my $progress = $grid->apply_deductions(@deductions);

is($progress, 2, 'the Type 1 deductions apply');
ok(!$roof->possibilities->[1] && !$roof->possibilities->[2],
    'the pair candidates are removed from the roof');
ok($roof->possibilities->[3], 'the roof keeps its extra candidate');

my $four_boxes = Grid->new;
$four_boxes->load_from_string('.' x 81);
set_possibilities($four_boxes->cell_from_row_column(0, 0), 1, 2);
set_possibilities($four_boxes->cell_from_row_column(0, 3), 1, 2);
set_possibilities($four_boxes->cell_from_row_column(3, 0), 1, 2);
set_possibilities($four_boxes->cell_from_row_column(3, 3), 1, 2, 3);

is(scalar(Sudoku::Strategy::UniqueRectangleType1->new->apply($four_boxes)), 0,
    'a rectangle spanning four boxes is not a Unique Rectangle');

done_testing();
