#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::XYWing;

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

my $pivot = set_possibilities($grid->cell_from_row_column(1, 1), 1, 2);
my $left  = set_possibilities($grid->cell_from_row_column(1, 4), 1, 3);
my $right = set_possibilities($grid->cell_from_row_column(4, 1), 2, 3);
my $target = $grid->cell_from_row_column(4, 4);

remove_candidate_except($grid, 3, $pivot, $left, $right, $target);

my @deductions = Sudoku::Strategy::XYWing->new->apply($grid);

is(deduction_for(\@deductions, $target, 3), 1, 'XY-Wing removes the shared pincer candidate');
is(scalar @deductions, 1, 'the fixture produces one XY-Wing deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/pivot/, 'deduction explains the pivot');
like($deductions[0]->reason, qr/sees both pincers/, 'deduction explains why the target is affected');

my $progress = $grid->apply_deductions(@deductions);

is($progress, 1, 'the XY-Wing deduction applies');
ok(!$target->possibilities->[3], 'candidate 3 is removed from the target');

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);
set_possibilities($invalid->cell_from_row_column(1, 1), 1, 2);
set_possibilities($invalid->cell_from_row_column(1, 4), 1, 3);
set_possibilities($invalid->cell_from_row_column(4, 1), 2, 4);

is(scalar(Sudoku::Strategy::XYWing->new->apply($invalid)), 0,
    'pincers without a common elimination candidate do not form an XY-Wing');

done_testing();
