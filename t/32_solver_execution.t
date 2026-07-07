#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Test qw(capture_stdout);

my $solved_puzzle = '123456789456789123789123456214365897365897214897214365531642978642978531978531642';

my $solver = Solver->new;
my $grid;

my $output = capture_stdout {
    $grid = $solver->run(
        puzzle_string => $solved_puzzle,
    );
};

isa_ok($grid, 'Grid', 'run returns a Grid object');
is($grid->solved, 81, 'run preserves a fully solved puzzle as solved');

is(
    join('', map { $_->value } @{ $grid->cells }),
    $solved_puzzle,
    'run returns a grid containing the expected cell values',
);

like(
    $output,
    qr/We have solved this puzzle\.\s+Final solution is:/,
    'run reports that an already solved puzzle is solved',
);

like(
    $output,
    qr/\Q$solved_puzzle\E/,
    'run prints the final solution string',
);

my $second_grid;
my $second_output = capture_stdout {
    $second_grid = $solver->run(
        puzzle_string => $solved_puzzle,
    );
};

isa_ok($second_grid, 'Grid', 'run can be called more than once');
is($second_grid->solved, 81, 'second run also returns a solved grid');
like($second_output, qr/We have solved this puzzle/, 'second run reports success');

isnt(
    $second_grid,
    $grid,
    'each run returns a new Grid object',
);

done_testing();
