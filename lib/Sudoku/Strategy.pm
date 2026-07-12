package Sudoku::Strategy;

use strict;
use warnings;

use Sudoku::Strategy::NakedSingles;
use Sudoku::Strategy::HiddenSingles;
use Sudoku::Strategy::PointingClaiming;
use Sudoku::Strategy::NakedPairs;
use Sudoku::Strategy::HiddenPairs;
use Sudoku::Strategy::NakedTriples;
use Sudoku::Strategy::HiddenTriples;
use Sudoku::Strategy::NakedQuads;
use Sudoku::Strategy::HiddenQuads;
use Sudoku::Strategy::XWing;
use Sudoku::Strategy::Swordfish;
use Sudoku::Strategy::Skyscraper;
use Sudoku::Strategy::TwoStringKite;
use Sudoku::Strategy::EmptyRectangle;
use Sudoku::Strategy::SimpleColoring;
use Sudoku::Strategy::XChains;
use Sudoku::Strategy::RemotePairs;
use Sudoku::Strategy::UniqueRectangleType1;
use Sudoku::Strategy::UniqueRectangleType2;
use Sudoku::Strategy::XYWing;
use Sudoku::Strategy::XYZWing;
use Sudoku::Strategy::WXYZWing;

my @ORDERED_STRATEGY_CLASSES = qw(
    Sudoku::Strategy::NakedSingles
    Sudoku::Strategy::HiddenSingles
    Sudoku::Strategy::PointingClaiming
    Sudoku::Strategy::NakedPairs
    Sudoku::Strategy::HiddenPairs
    Sudoku::Strategy::NakedTriples
    Sudoku::Strategy::HiddenTriples
    Sudoku::Strategy::NakedQuads
    Sudoku::Strategy::HiddenQuads
    Sudoku::Strategy::XWing
    Sudoku::Strategy::Swordfish
    Sudoku::Strategy::Skyscraper
    Sudoku::Strategy::TwoStringKite
    Sudoku::Strategy::EmptyRectangle
    Sudoku::Strategy::SimpleColoring
    Sudoku::Strategy::XChains
    Sudoku::Strategy::RemotePairs
    Sudoku::Strategy::XYWing
    Sudoku::Strategy::XYZWing
    Sudoku::Strategy::WXYZWing
    Sudoku::Strategy::UniqueRectangleType1
    Sudoku::Strategy::UniqueRectangleType2
);

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
