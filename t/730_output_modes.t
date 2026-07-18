#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use IPC::Open3;
use Symbol qw(gensym);
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

my ($debug_output, $debug_error, $debug_exit) = _run_cli(
    '--string'        => $puzzle,
    '--output'        => 'debug',
    '--grid-format'   => 'worksheet',
    '--character-set' => 'UNICODE-MIXED',
);

is($debug_exit, 0, 'debug CLI command with worksheet grid exits successfully');
is($debug_error, q{}, 'debug CLI command is quiet on stderr');

my ($pass_grid) = $debug_output =~ /^Pass 1\n-+\n(.*?)^\s+Naked Singles:/ms;
ok(defined $pass_grid, 'debug output includes a per-pass grid before strategy results');
like($pass_grid, qr/┏/, 'per-pass debug grid honors mixed Unicode corners');
like($pass_grid, qr/┃/, 'per-pass debug grid honors mixed Unicode major boundaries');
like($pass_grid, qr/│/, 'per-pass debug grid honors mixed Unicode minor boundaries');
unlike($pass_grid, qr/^\s*\+/m, 'per-pass debug grid no longer uses ASCII rules');

done_testing();

sub _run_cli {
    my (@args) = @_;

    my ($stdin, $stdout);
    my $stderr = gensym;
    my $pid = open3(
        $stdin,
        $stdout,
        $stderr,
        $^X,
        '-Ilib',
        'bin/sudoku.pl',
        @args,
    );
    close $stdin;

    binmode $stdout, ':encoding(UTF-8)';
    binmode $stderr, ':encoding(UTF-8)';
    my $output = do { local $/; <$stdout> // q{} };
    my $error = do { local $/; <$stderr> // q{} };
    waitpid $pid, 0;
    my $exit = $? >> 8;

    return ($output, $error, $exit);
}
