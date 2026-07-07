#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::More tests => 7;

BEGIN {
    use_ok('Sudoku');
    use_ok('Constants');
    use_ok('Types');
    use_ok('Cell');
    use_ok('Grid');
    use_ok('Solver');
}

is(
    $Sudoku::VERSION,
    '0.5.1',
    'Project version is correct',
);

