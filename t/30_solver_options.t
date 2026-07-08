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
    qr{Puzzle string must contain exactly 81 digits or \(0's, dots, dashes, or underscores for empty cells\)},
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


my ( $list_fh, $list_filename ) = tempfile();
print {$list_fh} "$puzzle_1 # first puzzle comment\n";
print {$list_fh} "$puzzle_2 # second puzzle comment\n";
close $list_fh;

is_deeply(
    [ $solver->puzzle_strings_from_file($list_filename) ],
    [ $puzzle_1, $puzzle_2 ],
    'puzzle_strings_from_file strips end-of-line comments from puzzle-list files',
);

my ( $grid_fh, $grid_filename ) = tempfile();
print {$grid_fh} "# single grid with comments and blanks\n";
print {$grid_fh} "003020600  # row 1\n";
print {$grid_fh} "900305001\n";
print {$grid_fh} "001806400\n";
print {$grid_fh} "\n";
print {$grid_fh} "008102900\n";
print {$grid_fh} "700000008\n";
print {$grid_fh} "006708200\n";
print {$grid_fh} "002609500\n";
print {$grid_fh} "800203009\n";
print {$grid_fh} "005010300\n";
close $grid_fh;

is_deeply(
    [ $solver->puzzle_strings_from_file($grid_filename) ],
    [ $puzzle_1 ],
    'puzzle_strings_from_file recognizes a single puzzle spread across nine rows',
);

my ( $mixed_fh, $mixed_filename ) = tempfile();
print {$mixed_fh} "12345678. # row 1\n";
print {$mixed_fh} "2345678.1\n";
print {$mixed_fh} "345678.12\n";
print {$mixed_fh} "45678.123\n";
print {$mixed_fh} "5678.1234\n";
print {$mixed_fh} "678.12345\n";
print {$mixed_fh} "78.123456\n";
print {$mixed_fh} "8_1234567\n";
print {$mixed_fh} "-12345678\n";
close $mixed_fh;

is_deeply(
    [ $solver->puzzle_strings_from_file($mixed_filename) ],
    [ '123456780234567801345678012456780123567801234678012345780123456801234567012345678' ],
    'single-grid files accept dots, underscores, dashes, and comments',
);

done_testing();
