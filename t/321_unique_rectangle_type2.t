#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::UniqueRectangleType2;

sub set_possibilities {
    my ($cell, @values) = @_;

    my %keep = map { ($_ => 1) } @values;
    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

sub remove_candidate_except {
    my ($grid, $candidate, @keep) = @_;

    my %keep = map { ("$_" => 1) } @keep;
    for my $cell (@{ $grid->cells }) {
        next if $keep{"$cell"};
        $cell->remove_possibility($candidate);
    }
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

my $floor_a = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2);
my $floor_b = set_possibilities($grid->cell_from_row_column(0, 3), 1, 2);
my $roof_a  = set_possibilities($grid->cell_from_row_column(1, 0), 1, 2, 3);
my $roof_b  = set_possibilities($grid->cell_from_row_column(1, 3), 1, 2, 3);
my $target  = $grid->cell_from_row_column(1, 6);

remove_candidate_except(
    $grid,
    3,
    $roof_a,
    $roof_b,
    $target,
);

my @deductions = Sudoku::Strategy::UniqueRectangleType2->new->apply($grid);

is(deduction_for(\@deductions, $target, 3), 1,
    'Type 2 removes the shared roof candidate from a common peer');
is(scalar @deductions, 1, 'the fixture produces one Type 2 deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/both contain extra candidate 3/,
    'deduction identifies the shared roof candidate');
like($deductions[0]->reason, qr/sees both roof cells/,
    'deduction explains why the target is affected');

my $progress = $grid->apply_deductions(@deductions);

is($progress, 1, 'the Type 2 deduction applies');
ok(!$target->possibilities->[3], 'candidate 3 is removed from the target');

my $different_extras = Grid->new;
$different_extras->load_from_string('.' x 81);
set_possibilities($different_extras->cell_from_row_column(0, 0), 1, 2);
set_possibilities($different_extras->cell_from_row_column(0, 3), 1, 2);
set_possibilities($different_extras->cell_from_row_column(1, 0), 1, 2, 3);
set_possibilities($different_extras->cell_from_row_column(1, 3), 1, 2, 4);

is(scalar(Sudoku::Strategy::UniqueRectangleType2->new->apply($different_extras)), 0,
    'roof cells with different extras do not form Type 2');

done_testing();
