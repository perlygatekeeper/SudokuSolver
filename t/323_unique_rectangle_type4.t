#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::UniqueRectangleType4;

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
    return scalar grep { $_->cell == $cell && $_->value == $value } @{$deductions};
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $floor_a = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2);
my $floor_b = set_possibilities($grid->cell_from_row_column(0, 3), 1, 2);
my $roof_a  = set_possibilities($grid->cell_from_row_column(1, 0), 1, 2, 3);
my $roof_b  = set_possibilities($grid->cell_from_row_column(1, 3), 1, 2, 4);

remove_candidate_except($grid, 1, $floor_a, $floor_b, $roof_a, $roof_b);

my @deductions = Sudoku::Strategy::UniqueRectangleType4->new->apply($grid);

is(deduction_for(\@deductions, $roof_a, 2), 1,
    'Type 4 removes the other rectangle candidate from the first roof');
is(deduction_for(\@deductions, $roof_b, 2), 1,
    'Type 4 removes the other rectangle candidate from the second roof');
is(scalar @deductions, 2, 'the fixture produces exactly two Type 4 deductions');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/appears only in those two cells/i,
    'deduction identifies the roof strong link');
like($deductions[0]->reason, qr/deadly rectangle/i,
    'deduction explains the uniqueness consequence');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 2, 'the Type 4 deductions apply');
ok(!$roof_a->possibilities->[2] && !$roof_b->possibilities->[2],
    'candidate 2 is removed from both roofs');

my $no_strong_link = Grid->new;
$no_strong_link->load_from_string('.' x 81);
set_possibilities($no_strong_link->cell_from_row_column(0, 0), 1, 2);
set_possibilities($no_strong_link->cell_from_row_column(0, 3), 1, 2);
set_possibilities($no_strong_link->cell_from_row_column(1, 0), 1, 2, 3);
set_possibilities($no_strong_link->cell_from_row_column(1, 3), 1, 2, 4);

is(scalar(Sudoku::Strategy::UniqueRectangleType4->new->apply($no_strong_link)), 0,
    'roof cells without a strong link do not form Type 4');

done_testing();
