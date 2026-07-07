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
    Sudoku::Statistics
    Sudoku::Difficulty
    Sudoku::Canonical
    Sudoku::Explain
    Sudoku::Hint
    Sudoku::Strategy
    Sudoku::Strategy::Base
    Sudoku::Strategy::NakedSingles
    Sudoku::Strategy::HiddenSingles
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
