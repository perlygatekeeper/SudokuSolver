package Sudoku::Test;

use strict;
use warnings;

use Exporter 'import';
use Test::More ();

our @EXPORT_OK = qw(
    project_modules
    test_project_modules
);

my @PROJECT_MODULES = qw(
    Sudoku
    Constants
    Types
    Cell
    Grid
    Solver
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

1;
