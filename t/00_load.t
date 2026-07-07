#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Sudoku::Test qw(test_project_modules);

test_project_modules();

is(
    $Sudoku::VERSION,
    '0.5.1',
    'Project version is correct',
);

done_testing();
