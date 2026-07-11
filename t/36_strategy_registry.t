#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Sudoku::Strategy;
use Sudoku::Strategy::Base;

my @classes = Sudoku::Strategy->ordered_strategy_classes;

is_deeply(
    \@classes,
    [
        'Sudoku::Strategy::NakedSingles',
        'Sudoku::Strategy::HiddenSingles',
        'Sudoku::Strategy::PointingClaiming',
        'Sudoku::Strategy::NakedPairs',
        'Sudoku::Strategy::HiddenPairs',
        'Sudoku::Strategy::NakedTriples',
        'Sudoku::Strategy::HiddenTriples',
        'Sudoku::Strategy::XWing',
        'Sudoku::Strategy::RemotePairs',
    ],
    'registry returns strategies in canonical solving order',
);

my @strategies = Sudoku::Strategy->strategies;

is(scalar @strategies, scalar @classes, 'registry instantiates one object per strategy class');

for my $strategy (@strategies) {
    isa_ok($strategy, 'Sudoku::Strategy::Base');
    can_ok($strategy, qw(name apply));
}

is_deeply(
    [ Sudoku::Strategy->ordered_strategy_names ],
    [
        'Naked Singles',
        'Hidden Singles',
        'Pointing / Claiming',
        'Naked Pairs',
        'Hidden Pairs',
        'Naked Triples',
        'Hidden Triples',
        'X-Wing',
        'Remote Pairs',
    ],
    'registry exposes canonical strategy names',
);

done_testing();
