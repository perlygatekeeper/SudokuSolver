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
        'Sudoku::Strategy::NakedQuads',
        'Sudoku::Strategy::HiddenQuads',
        'Sudoku::Strategy::XWing',
        'Sudoku::Strategy::RemotePairs',
        'Sudoku::Strategy::XYWing',
        'Sudoku::Strategy::XYZWing',
        'Sudoku::Strategy::WXYZWing',
        'Sudoku::Strategy::UniqueRectangleType1',
        'Sudoku::Strategy::UniqueRectangleType2',
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
        'Naked Quads',
        'Hidden Quads',
        'X-Wing',
        'Remote Pairs',
        'XY-Wing',
        'XYZ-Wing',
        'WXYZ-Wing',
        'Unique Rectangle Type 1',
        'Unique Rectangle Type 2',
    ],
    'registry exposes canonical strategy names',
);

done_testing();
