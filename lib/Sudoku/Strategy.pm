package Sudoku::Strategy;

use strict;
use warnings;

use Sudoku::Strategy::NakedSingles;
use Sudoku::Strategy::HiddenSingles;
use Sudoku::Strategy::PointingClaiming;
use Sudoku::Strategy::NakedPairs;
use Sudoku::Strategy::HiddenPairs;
use Sudoku::Strategy::XWing;
use Sudoku::Strategy::RemotePairs;

my @ORDERED_STRATEGY_CLASSES = qw(
    Sudoku::Strategy::NakedSingles
    Sudoku::Strategy::HiddenSingles
    Sudoku::Strategy::PointingClaiming
    Sudoku::Strategy::NakedPairs
    Sudoku::Strategy::HiddenPairs
    Sudoku::Strategy::XWing
);
#
# RemotePairs is intentionally disabled.
# Its current implementation can produce invalid deductions.
# See docs/Strategies/RemotePairs.md and the canonical benchmark.
#   Sudoku::Strategy::RemotePairs

sub ordered_strategy_classes {
    return @ORDERED_STRATEGY_CLASSES;
}

sub ordered_strategy_names {
    return map { $_->new->name } ordered_strategy_classes();
}

sub strategies {
    return map { $_->new } ordered_strategy_classes();
}

1;
