#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use lib 'lib';

use Solver;

my $solver = Solver->new;

my $puzzle_1 = '003020600900305001001806400008102900700000008006708200002609500800203009005010300';
my $puzzle_2 = '200080300060070084030500209000105408000000000402706000301007040720040060004010003';
my $dotted   = '...020600900305001001806400008102900700000008006708200002609500800203009005010300';

is(
    $solver->normalize_puzzle_string($puzzle_1),
    $puzzle_1,
    'normalize_puzzle_string accepts an 81-digit puzzle string',
);

is(
    $solver->normalize_puzzle_string($dotted),
    '000020600900305001001806400008102900700000008006708200002609500800203009005010300',
    'normalize_puzzle_string converts dots to zeroes',
);

is(
    $solver->normalize_puzzle_string("003020600\n900305001\n001806400\n008102900\n700000008\n006708200\n002609500\n800203009\n005010300"),
    $puzzle_1,
    'normalize_puzzle_string removes embedded whitespace',
);

my $error = do {
    local $@;
    eval { $solver->normalize_puzzle_string('123') };
    $@;
};
like(
    $error,
    qr/Puzzle string must contain exactly 81 digits or \(0's, dots, dashes, or underscores for empty cells\)/,
    'normalize_puzzle_string rejects malformed puzzle strings',
);

my ( $fh, $filename ) = tempfile();
print {$fh} "# comment line\n";
print {$fh} "\n";
print {$fh} "$puzzle_1\n";
print {$fh} "$puzzle_2\n";
close $fh;

my @puzzles = $solver->puzzle_strings_from_file($filename);

is_deeply(
    \@puzzles,
    [ $puzzle_1, $puzzle_2 ],
    'puzzle_strings_from_file reads puzzles and skips comments/blanks',
);

is(
    $solver->puzzle_string_from_options(
        puzzle_file  => $filename,
        puzzle_index => 2,
    ),
    $puzzle_2,
    'puzzle_string_from_options selects a 1-based puzzle index',
);

is(
    $solver->puzzle_string_from_options(
        puzzle_string => $dotted,
    ),
    '000020600900305001001806400008102900700000008006708200002609500800203009005010300',
    'puzzle_string_from_options prefers an explicit puzzle string',
);

$error = do {
    local $@;
    eval {
        $solver->puzzle_string_from_options(
            puzzle_file  => $filename,
            puzzle_index => 3,
        );
    };
    $@;
};
like(
    $error,
    qr/Puzzle number must be between 1 and 2/,
    'puzzle_string_from_options rejects an out-of-range puzzle index',
);

done_testing();
