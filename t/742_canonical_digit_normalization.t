#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Sudoku::Canonical qw(normalize_digits);
use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Symmetry;

my $puzzle =
    '500000030'
  . '040000000'
  . '000700000'
  . '000000000'
  . '000020000'
  . '000000000'
  . '000000600'
  . '000000000'
  . '100000000';

my $result = Sudoku::Canonical->digit_normal_form($puzzle);
is $result->stage, 'digit-normal', 'result identifies the normalization stage';
is $result->puzzle,
    '100000020'
  . '030000000'
  . '000400000'
  . '000000000'
  . '000050000'
  . '000000000'
  . '000000600'
  . '000000000'
  . '700000000',
    'digits are renamed in row-major order of first appearance';

is normalize_digits($puzzle), $result->puzzle,
    'functional helper returns the normalized puzzle string';
is $result->transform->apply_puzzle($puzzle), $result->puzzle,
    'result records the exact symmetry transform used';
is $result->transform->inverse->apply_puzzle($result->puzzle), $puzzle,
    'recorded transform is fully invertible';
is clue_count($result->puzzle), clue_count($puzzle),
    'digit normalization preserves clue count';

my $renamed = Sudoku::Symmetry->new(
    digits => [ 9, 3, 7, 1, 8, 2, 6, 5, 4 ],
)->apply_puzzle($puzzle);
is normalize_digits($renamed), normalize_digits($puzzle),
    'digit-permuted equivalent puzzles have the same digit normal form';

is normalize_digits(normalize_digits($puzzle)), normalize_digits($puzzle),
    'digit normalization is idempotent';

my $sparse = '900000000' . ('0' x 72);
my $sparse_result = Sudoku::Canonical->digit_normal_form($sparse);
is substr($sparse_result->puzzle, 0, 1), '1',
    'a sparse puzzle normalizes its first seen digit to one';
is $sparse_result->transform->inverse->apply_puzzle($sparse_result->puzzle),
    $sparse,
    'missing digits are assigned deterministically in a complete permutation';

for my $bad (undef, q{}, '0' x 80, ('0' x 80) . 'x') {
    my $ok = eval { Sudoku::Canonical->digit_normal_form($bad); 1 };
    ok !$ok, 'invalid puzzle input is rejected';
    like $@, qr/(?:required|81 characters|digits 0 through 9)/,
        'invalid puzzle rejection has a useful error';
}

done_testing();
