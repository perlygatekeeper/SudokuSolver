#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::XYZWing;

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

    my %keep = map { ($_ => 1) } @keep;
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

my $pivot = set_possibilities($grid->cell_from_row_column(1, 1), 1, 2, 3);
my $left  = set_possibilities($grid->cell_from_row_column(1, 4), 1, 3);
my $right = set_possibilities($grid->cell_from_row_column(0, 2), 2, 3);
my $target = $grid->cell_from_row_column(1, 2);

remove_candidate_except($grid, 3, $pivot, $left, $right, $target);

my @deductions = Sudoku::Strategy::XYZWing->new->apply($grid);

is(deduction_for(\@deductions, $target, 3), 1, 'XYZ-Wing removes the common candidate');
is(scalar @deductions, 1, 'the fixture produces one XYZ-Wing deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/sees the pivot and both pincers/, 'deduction explains the common peer requirement');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 1, 'the XYZ-Wing deduction applies');
ok(!$target->possibilities->[3], 'candidate 3 is removed from the target');

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);
set_possibilities($invalid->cell_from_row_column(1, 1), 1, 2, 3);
set_possibilities($invalid->cell_from_row_column(1, 4), 1, 3);
set_possibilities($invalid->cell_from_row_column(0, 2), 2, 4);

is(scalar(Sudoku::Strategy::XYZWing->new->apply($invalid)), 0,
    'pincers outside the pivot candidate set do not form an XYZ-Wing');

done_testing();
