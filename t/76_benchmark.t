#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use lib 'lib';

use Sudoku::Benchmark;

my $solved_puzzle = '123456789456789123789123456234567891567891234891234567345678912678912345912345678';
my $stalled_puzzle = '000000010400000000020000000000050407008000300001090000300400200050100000000806000';

my ( $fh, $filename ) = tempfile();
print {$fh} "$solved_puzzle\n";
print {$fh} "$stalled_puzzle\n";
close $fh;

my $benchmark = Sudoku::Benchmark->new( file => $filename );
isa_ok($benchmark, 'Sudoku::Benchmark');

$benchmark->run;

is($benchmark->processed, 2, 'benchmark processed two puzzles');
is($benchmark->solved, 1, 'benchmark counts solved puzzles');
is($benchmark->stalled, 1, 'benchmark counts stalled puzzles');
is($benchmark->contradictions, 0, 'benchmark counts contradictions');
ok($benchmark->total_elapsed >= 0, 'benchmark records total elapsed time');
ok($benchmark->average_elapsed >= 0, 'benchmark records average elapsed time');

my @unsolved = $benchmark->unsolved_results;
is(scalar @unsolved, 1, 'benchmark reports unsolved puzzles');
is($unsolved[0]->{index}, 2, 'unsolved result records puzzle index');
is($unsolved[0]->{status}, 'stalled', 'unsolved result records status');

my $summary = $benchmark->summary_text;
like($summary, qr/Canonical 17-Clue Benchmark/, 'summary has benchmark title');
like($summary, qr/Puzzles processed : 2/, 'summary reports puzzle count');
like($summary, qr/Solved\s+: 1/, 'summary reports solved count');
like($summary, qr/Stalled\s+: 1/, 'summary reports stalled count');
like($summary, qr/Unsolved puzzles/, 'summary lists unsolved puzzles');

my $usage = $benchmark->highest_strategy_usage;
isa_ok($usage, 'HASH', 'highest_strategy_usage returns a hash reference');

done_testing();
