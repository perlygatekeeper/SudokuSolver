#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Sudoku::CoordinateEncoding qw(
    clue_count
    clue_locations
    encode_puzzle
    validate_puzzle_string
);

my $puzzle =
    '000000000000000001000002030000003020001040000005000060030000004070080009620007000';

is length($puzzle), 81, 'fixture contains 81 cells';
is clue_count($puzzle), 17, 'clue_count reports seventeen clues';

is(
    encode_puzzle($puzzle),
    '2953-364892-384672-5579-63-6891-8296-85-89',
    'digit-grouped coordinates use the specified stable encoding',
);

is length(encode_puzzle($puzzle)), 42,
    'a seventeen-clue encoding is exactly 42 characters';

my @locations = clue_locations($puzzle);
is scalar(@locations), 17, 'clue_locations returns one entry per clue';
is_deeply(
    $locations[0],
    { digit => 1, row => 2, column => 9 },
    'first clue location is reported in row-major order',
);

{
    package Local::GridLike;
    sub as_puzzle_string { $_[0]->{puzzle} }
}
my $grid_like = bless { puzzle => $puzzle }, 'Local::GridLike';
is encode_puzzle($grid_like), encode_puzzle($puzzle),
    'encoder accepts an object exposing as_puzzle_string';

is(
    encode_puzzle('0' x 81),
    '--------',
    'empty puzzle preserves all nine empty digit groups',
);

for my $case (
    [ undef,      qr/Puzzle is required/, 'undefined puzzle is rejected' ],
    [ '0' x 80,   qr/exactly 81/,         'short puzzle is rejected' ],
    [ ('0' x 80) . '.', qr/only digits 0 through 9/, 'non-normalized puzzle is rejected' ],
) {
    my ($input, $pattern, $name) = @$case;
    my $ok = eval { validate_puzzle_string($input); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name with useful error";
}

done_testing();
