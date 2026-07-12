#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::XChains;

sub keep_candidate_only_at {
    my ( $grid, $digit, @coordinates ) = @_;

    my %keep = map { ( join(q{:}, @{$_}) => 1 ) } @coordinates;

    for my $row (0 .. 8) {
        for my $column (0 .. 8) {
            next if $keep{ join(q{:}, $row, $column) };
            $grid->cell_from_row_column($row, $column)
                ->remove_possibility($digit);
        }
    }
}

sub deduction_for {
    my ( $deductions, $cell, $digit ) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $digit
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::XChains->new;
is($strategy->name, 'X-Chains', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Candidate 6 contains the alternating chain:
#
#   R1C1 =S= R1C4 -W- R2C5 =S= R6C5
#
# R6C1 sees both endpoints, so candidate 6 can be removed there.
# Additional candidates prevent the weak link and target visibility units from
# accidentally becoming conjugate pairs of their own.
keep_candidate_only_at(
    $grid,
    6,
    [ 0, 0 ],    # R1C1 first endpoint
    [ 0, 3 ],    # R1C4 strong link with R1C1
    [ 1, 4 ],    # R2C5 weak link through box 2
    [ 5, 4 ],    # R6C5 strong link with R2C5
    [ 5, 0 ],    # R6C1 target
    [ 2, 5 ],    # prevents box-2 conjugate pair
    [ 7, 0 ],    # prevents column-1 conjugate pair
    [ 5, 7 ],    # prevents row-6 conjugate pair
);

my $target = $grid->cell_from_row_column(5, 0);
my @deductions = $strategy->apply($grid);

ok(@deductions >= 1, 'X-Chain finds at least one elimination');
is(deduction_for(\@deductions, $target, 6), 1,
    'X-Chain removes candidate from a common peer of its endpoints');

my ($deduction) = grep { $_->cell == $target && $_->value == 6 } @deductions;
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'X-Chains', 'deduction records strategy');
is($deduction->action, 'remove_candidate',
    'deduction removes a candidate');
like($deduction->reason, qr/alternating X-Chain/,
    'reason identifies the alternating chain');
like($deduction->reason, qr/=S=.*-W-.*=S=/,
    'reason displays strong and weak links');
like($deduction->explanation, qr/cannot both be false/,
    'explanation states the endpoint inference');

is($grid->apply_deductions($deduction), 1,
    'X-Chain deduction applies');
ok(!$target->possibilities->[6],
    'target loses candidate');

my $no_target_grid = Grid->new;
$no_target_grid->load_from_string('.' x 81);
keep_candidate_only_at(
    $no_target_grid,
    7,
    [ 0, 0 ], [ 0, 3 ], [ 1, 4 ], [ 5, 4 ],
    [ 2, 5 ],
);

is(scalar $strategy->apply($no_target_grid), 0,
    'alternating path without a common-peer target makes no deduction');

done_testing();
