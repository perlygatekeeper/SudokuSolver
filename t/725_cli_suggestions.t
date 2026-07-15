#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 'lib';
use Sudoku::CLI::Suggestion qw(suggest_value);

is(
    suggest_value(input => 'htlm', choices => [qw(markdown html svg png pdf)]),
    'html',
    'adjacent transposition suggests html',
);

is(
    suggest_value(input => 'makrdown', choices => [qw(markdown html svg)]),
    'markdown',
    'longer adjacent transposition is recognized',
);

is(
    suggest_value(input => 'UNICODE-MIXD', choices => [qw(ASCII UNICODE_LIGHT UNICODE_MIXED)]),
    'UNICODE_MIXED',
    'comparison normalizes case and hyphen versus underscore',
);

is(
    suggest_value(input => 'candidate-lsit', choices => [qw(candidate-list candidate-line candidate-json)]),
    'candidate-list',
    'compound value transposition is recognized',
);

is(
    suggest_value(input => 'bananas', choices => [qw(html svg png pdf)]),
    undef,
    'unrelated input does not receive a suggestion',
);

sub run_cli {
    my (@args) = @_;
    my $command = join q{ }, map { quotemeta $_ } ($^X, '-Ilib', 'bin/sudoku.pl', @args);
    my $output = qx{$command 2>&1};
    return ($? >> 8, $output);
}

{
    my ($status, $output) = run_cli('--grid-format', 'htlm', '--file', 'Puzzles/Puzzle3.txt');
    isnt($status, 0, 'misspelled grid format fails');
    like($output, qr/Unknown grid format 'htlm'/, 'grid-format error identifies bad value');
    like($output, qr/Did you mean 'html'\?/, 'grid-format error suggests html');
}

{
    my ($status, $output) = run_cli('--color-theme', 'brigth', '--file', 'Puzzles/Puzzle3.txt');
    isnt($status, 0, 'misspelled color theme fails');
    like($output, qr/Did you mean 'bright'\?/, 'color-theme error suggests bright');
}

{
    my ($status, $output) = run_cli('--output', 'nomral', '--file', 'Puzzles/Puzzle3.txt');
    isnt($status, 0, 'misspelled output mode fails');
    like($output, qr/Did you mean 'normal'\?/, 'output-mode error suggests normal');
}

{
    my ($status, $output) = run_cli('--character-set', 'unicode-mixd', '--file', 'Puzzles/Puzzle3.txt');
    isnt($status, 0, 'misspelled character set fails');
    like($output, qr/Did you mean 'UNICODE_MIXED'\?/, 'character-set error suggests Unicode mixed');
}

{
    my ($status, $output) = run_cli('--grid-format', 'bananas', '--file', 'Puzzles/Puzzle3.txt');
    isnt($status, 0, 'unrelated grid format fails');
    unlike($output, qr/Did you mean/, 'unrelated grid format has no misleading suggestion');
}

done_testing();
