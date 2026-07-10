#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Test qw(capture_stdout);

my $puzzle_07 = '000000012050400000000000030700600400001000000000080000920000800000510700000003000';
my $solution_07 = '364978512152436978879125634738651429691247385245389167923764851486512793517893246';

my $solver = Solver->new;
my $grid;

my $output = capture_stdout {
    $grid = $solver->run(
        puzzle_string => $puzzle_07,
    );
};

isa_ok($grid, 'Grid', 'regression run returns a Grid object');
is($grid->solved, 81, 'sudoku17 puzzle 07 is solved completely');

is(
    join('', map { $_->value } @{ $grid->cells }),
    $solution_07,
    'sudoku17 puzzle 07 solution matches the legacy documented solution',
);

like(
    $output,
    qr/^Solved$/m,
    'solver reports successful completion',
);

like(
    $output,
    qr/\Q$solution_07\E/,
    'solver output includes the final solution string',
);

done_testing();
