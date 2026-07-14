#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use lib 'lib';

use Sudoku::Benchmark;

my $solved_puzzle = '123456789456789123789123456234567891567891234891234567345678912678912345912345678';
my $stalled_puzzle = '0' x 81;

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

my $manual = Sudoku::Benchmark->new( file => $filename );
$manual->results([
    {
        status => 'solved',
        strategy_contributions => {
            'Naked Singles' => {
                deductions            => 3,
                cells_solved          => 3,
                candidates_eliminated => 0,
            },
            'Naked Triples' => {
                deductions            => 2,
                cells_solved          => 0,
                candidates_eliminated => 2,
            },
        },
    },
    {
        status => 'stalled',
        strategy_contributions => {
            'Naked Singles' => {
                deductions            => 1,
                cells_solved          => 1,
                candidates_eliminated => 0,
            },
        },
    },
]);

my $contribution = $manual->strategy_contributions;
is($contribution->{'Naked Singles'}{puzzles_used}, 2,
    'strategy contributions count puzzles using a strategy');
is($contribution->{'Naked Singles'}{deductions}, 4,
    'strategy contributions total deductions');
is($contribution->{'Naked Singles'}{cells_solved}, 4,
    'strategy contributions total solved cells');
is($contribution->{'Naked Triples'}{candidates_eliminated}, 2,
    'strategy contributions total candidate eliminations');
is($contribution->{'Hidden Quads'}{deductions}, 0,
    'strategy contributions include registered strategies with zero use');

my $manual_summary = $manual->summary_text;
like($manual_summary, qr/Strategy contributions/,
    'summary includes strategy contributions section');
like($manual_summary, qr/Naked Triples\s+1\s+2\s+0\s+2/,
    'summary reports triple contribution counts');
like($manual_summary, qr/Hidden Quads\s+0\s+0\s+0\s+0/,
    'summary displays unused strategies');

done_testing();
