#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Test qw(capture_stdout);

my $puzzle = '0' x 81;

my $normal_solver = Solver->new;
my $normal_output = capture_stdout {
    $normal_solver->run(
        puzzle_string => $puzzle,
        output_mode   => 'normal',
    );
};

unlike($normal_output, qr/^Pass 1/m, 'normal mode does not print pass-level trace output');
unlike($normal_output, qr/Restarting from Naked Singles/, 'normal mode does not print restart notices');
like($normal_output, qr/^Stalled$/m, 'normal mode prints final status');
like($normal_output, qr/Solved cells: 0 \/ 81/, 'normal mode reports solved-cell count');

my $trace_solver = Solver->new;
my $trace_output = capture_stdout {
    $trace_solver->run(
        puzzle_string => $puzzle,
        output_mode   => 'trace',
    );
};

like($trace_output, qr/^Pass 1/m, 'trace mode prints pass-level output');
like($trace_output, qr/Naked Singles: no deductions/, 'trace mode prints strategy attempts');
like($trace_output, qr/End Pass 1: no progress/, 'trace mode prints pass completion');

my $quiet_solver = Solver->new;
my $quiet_output = capture_stdout {
    $quiet_solver->run(
        puzzle_string => $puzzle,
        output_mode   => 'quiet',
    );
};

is($quiet_output, q{}, 'quiet mode suppresses solver output');

done_testing();
