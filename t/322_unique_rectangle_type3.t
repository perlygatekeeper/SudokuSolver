#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::UniqueRectangleType3;

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

my $floor_a   = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2);
my $floor_b   = set_possibilities($grid->cell_from_row_column(0, 3), 1, 2);
my $roof_a    = set_possibilities($grid->cell_from_row_column(1, 0), 1, 2, 3);
my $roof_b    = set_possibilities($grid->cell_from_row_column(1, 3), 1, 2, 4);
my $companion = set_possibilities($grid->cell_from_row_column(1, 6), 3, 4);
my $target    = set_possibilities($grid->cell_from_row_column(1, 7), 3, 4, 5);

remove_candidate_except($grid, 3, $roof_a, $companion, $target);
remove_candidate_except($grid, 4, $roof_b, $companion, $target);

my @deductions = Sudoku::Strategy::UniqueRectangleType3->new->apply($grid);

is(deduction_for(\@deductions, $target, 3), 1,
    'Type 3 removes the first extra candidate from the target');
is(deduction_for(\@deductions, $target, 4), 1,
    'Type 3 removes the second extra candidate from the target');
is(scalar @deductions, 2, 'the fixture produces exactly two Type 3 deductions');
isa_ok($deductions[0], 'Sudoku::Deduction');
like($deductions[0]->reason, qr/virtual cell/i,
    'deduction explains the virtual roof cell');
like($deductions[0]->reason, qr/naked subset/i,
    'deduction explains the supporting subset');

my $progress = $grid->apply_deductions(@deductions);
is($progress, 2, 'the Type 3 deductions apply');
ok(!$target->possibilities->[3] && !$target->possibilities->[4],
    'both subset candidates are removed from the target');
ok($target->possibilities->[5], 'the target keeps its unrelated candidate');

my $no_subset = Grid->new;
$no_subset->load_from_string('.' x 81);
set_possibilities($no_subset->cell_from_row_column(0, 0), 1, 2);
set_possibilities($no_subset->cell_from_row_column(0, 3), 1, 2);
set_possibilities($no_subset->cell_from_row_column(1, 0), 1, 2, 3);
set_possibilities($no_subset->cell_from_row_column(1, 3), 1, 2, 4);

is(scalar(Sudoku::Strategy::UniqueRectangleType3->new->apply($no_subset)), 0,
    'roof extras without a supporting subset do not form Type 3');

done_testing();
