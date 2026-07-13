#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::AIC;
use Sudoku::Strategy::GroupedAIC;

sub set_possibilities {
    my ( $cell, @values ) = @_;
    my %keep = map { $_ => 1 } @values;
    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }
    return $cell;
}

sub retain_candidate_only_at {
    my ( $grid, $digit, @keep ) = @_;
    my %keep = map { $_ => 1 } @keep;

    for my $cell ( @{ $grid->cells } ) {
        next if $keep{$cell};
        $cell->remove_possibility($digit);
    }
}

sub deduction_for {
    my ( $deductions, $cell, $value ) = @_;
    return scalar grep {
        $_->cell == $cell && $_->value == $value
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::GroupedAIC->new;
is($strategy->name, 'Grouped AIC', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Grouped AIC:
# R2C3(7) =S= {R1C1,R1C2}(7) -W- R1C5(7)
#          =S= R1C5(8) -W- R5C5(8) =S= R5C5(7)
# R5C3 sees both candidate-7 endpoints and loses candidate 7.
my $first     = $grid->cell_from_row_column(1, 2); # R2C3
my $group_1   = $grid->cell_from_row_column(0, 0); # R1C1
my $group_2   = $grid->cell_from_row_column(0, 1); # R1C2
my $middle_1  = set_possibilities(
    $grid->cell_from_row_column(0, 4), 7, 8,
); # R1C5
my $middle_2  = set_possibilities(
    $grid->cell_from_row_column(4, 4), 7, 8,
); # R5C5
my $target    = $grid->cell_from_row_column(4, 2); # R5C3

retain_candidate_only_at(
    $grid, 7,
    $first, $group_1, $group_2, $middle_1, $middle_2, $target,
);
retain_candidate_only_at($grid, 8, $middle_1, $middle_2);

my @deductions = $strategy->apply($grid);
is(deduction_for(\@deductions, $target, 7), 1,
    'Grouped AIC removes a candidate seen by both endpoints');

my ($deduction) = grep {
    $_->cell == $target && $_->value == 7
} @deductions;
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'Grouped AIC', 'deduction records strategy');
like($deduction->reason, qr/\{R1C1,R1C2\}\(7\)/,
    'reason displays a grouped candidate node');
like($deduction->reason, qr/=S=.*-W-.*=S=/,
    'reason displays a grouped alternating chain');

my @ordinary_deductions = Sudoku::Strategy::AIC->new->apply($grid);
is(deduction_for(\@ordinary_deductions, $target, 7), 0,
    'ordinary AIC does not duplicate the grouped elimination');

my $broken = Grid->new;
$broken->load_from_string('.' x 81);
my $broken_first = $broken->cell_from_row_column(1, 2);
my $broken_g1    = $broken->cell_from_row_column(0, 0);
my $broken_g2    = $broken->cell_from_row_column(0, 1);
my $broken_m1    = set_possibilities(
    $broken->cell_from_row_column(0, 4), 7, 8,
);
my $broken_m2    = set_possibilities(
    $broken->cell_from_row_column(5, 5), 7, 8,
);
my $broken_target = $broken->cell_from_row_column(1, 4);
retain_candidate_only_at(
    $broken, 7,
    $broken_first, $broken_g1, $broken_g2,
    $broken_m1, $broken_m2, $broken_target,
);
retain_candidate_only_at($broken, 8, $broken_m1, $broken_m2);

is(scalar $strategy->apply($broken), 0,
    'broken weak link does not form a Grouped AIC');

done_testing();
