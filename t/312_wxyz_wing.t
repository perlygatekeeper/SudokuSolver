#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::WXYZWing;

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

my $pivot = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2, 3, 4);
my $one   = set_possibilities($grid->cell_from_row_column(0, 1), 1, 4);
my $two   = set_possibilities($grid->cell_from_row_column(1, 0), 2, 4);
my $three = set_possibilities($grid->cell_from_row_column(1, 1), 3, 4);
my $target = $grid->cell_from_row_column(2, 2);

remove_candidate_except($grid, 4, $pivot, $one, $two, $three, $target);

my @deductions = Sudoku::Strategy::WXYZWing->new->apply($grid);

is(deduction_for(\@deductions, $target, 4), 1, 'WXYZ-Wing removes the shared pincer candidate');
is(scalar @deductions, 1, 'the fixture produces one WXYZ-Wing deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/three pincers/, 'deduction explains the three-pincer pattern');
like($deductions[0]->reason, qr/sees every pattern cell/, 'deduction explains why the target is affected');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 1, 'the WXYZ-Wing deduction applies');
ok(!$target->possibilities->[4], 'candidate 4 is removed from the target');

my $invalid = Grid->new;
$invalid->load_from_string('.' x 81);
set_possibilities($invalid->cell_from_row_column(0, 0), 1, 2, 3, 4);
set_possibilities($invalid->cell_from_row_column(0, 1), 1, 4);
set_possibilities($invalid->cell_from_row_column(1, 0), 2, 4);
set_possibilities($invalid->cell_from_row_column(1, 1), 2, 4);

is(scalar(Sudoku::Strategy::WXYZWing->new->apply($invalid)), 0,
    'three pincers must pair the shared candidate with three distinct values');

done_testing();
