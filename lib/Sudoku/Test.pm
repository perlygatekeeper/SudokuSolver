package Sudoku::Test;

use strict;
use warnings;

use Exporter 'import';
use Test::More ();

our @EXPORT_OK = qw(
    project_modules
    test_project_modules
    capture_stdout
);

my @PROJECT_MODULES = qw(
    Sudoku
    Constants
    Types
    Cell
    Grid
    Solver
    Sudoku::Deduction
    Sudoku::Contradiction
    Sudoku::Benchmark
    Sudoku::Statistics
    Sudoku::Difficulty
    Sudoku::Canonical
    Sudoku::Explain
    Sudoku::Hint
    Sudoku::Hypothetical
    Sudoku::Hypothetical::Result
    Sudoku::Render::Text
    Sudoku::Strategy
    Sudoku::Strategy::Base
    Sudoku::Strategy::NakedSingles
    Sudoku::Strategy::HiddenSingles
    Sudoku::Strategy::PointingClaiming
    Sudoku::Strategy::NakedPairs
    Sudoku::Strategy::HiddenPairs
    Sudoku::Subset
    Sudoku::Strategy::NakedTriples
    Sudoku::Strategy::HiddenTriples
    Sudoku::Strategy::NakedQuads
    Sudoku::Strategy::HiddenQuads
    Sudoku::Fish
    Sudoku::InferenceNode
    Sudoku::StrongLinks
    Sudoku::Strategy::XWing
    Sudoku::Strategy::Swordfish
    Sudoku::Strategy::Jellyfish
    Sudoku::Strategy::Skyscraper
    Sudoku::Strategy::TwoStringKite
    Sudoku::Strategy::EmptyRectangle
    Sudoku::Strategy::GroupedL1Wing
    Sudoku::Strategy::SimpleColoring
    Sudoku::Strategy::XChains
    Sudoku::Strategy::MultiColoring
    Sudoku::Strategy::RemotePairs
    Sudoku::Uniqueness
    Sudoku::Strategy::UniqueRectangleType1
    Sudoku::Strategy::UniqueRectangleType2
    Sudoku::Strategy::UniqueRectangleType3
    Sudoku::Strategy::UniqueRectangleType4
    Sudoku::Wing
    Sudoku::Strategy::XYWing
    Sudoku::Strategy::XYZWing
    Sudoku::Strategy::WXYZWing
    Sudoku::Strategy::XYChains
    Sudoku::Strategy::AIC
    Sudoku::Strategy::GroupedAIC
);

sub project_modules {
    return @PROJECT_MODULES;
}

sub test_project_modules {
    my @modules = @_ ? @_ : project_modules();

    for my $module (@modules) {
        Test::More::use_ok($module);
    }

    return @modules;
}

sub capture_stdout (&) {
    my ($code) = @_;
    my $output = '';

    open my $stdout, '>', \$output
        or die "Could not open scalar stdout handle: $!";

    local *STDOUT = $stdout;
    $code->();

    return $output;
}

1;
