use strict;
use warnings;

use Test::More;
use lib '.';

use Sudoku::Canonical qw(normalize_rows);
use Sudoku::Symmetry;

my $puzzle =
      '000000010'
    . '400000000'
    . '020000000'
    . '000050407'
    . '008000300'
    . '001090000'
    . '300400200'
    . '050100000'
    . '000806000';

my $result = Sudoku::Canonical->row_normal_form($puzzle);
is $result->stage, 'row-normal',
    'row normal form identifies its normalization stage';
is length($result->puzzle), 81,
    'row normal form remains an 81-character puzzle';
is $result->transform->apply_puzzle($puzzle), $result->puzzle,
    'recorded transform produces the row-normal puzzle';
is $result->transform->inverse->apply_puzzle($result->puzzle), $puzzle,
    'recorded transform is invertible';

is normalize_rows(normalize_rows($puzzle)), normalize_rows($puzzle),
    'row normalization is idempotent';

my @row_transforms = (
    Sudoku::Symmetry->new(bands => [ 2, 0, 1 ]),
    Sudoku::Symmetry->new(rows => [ [ 2, 0, 1 ], [ 1, 2, 0 ], [ 0, 2, 1 ] ]),
    Sudoku::Symmetry->new(
        bands => [ 1, 2, 0 ],
        rows  => [ [ 1, 0, 2 ], [ 2, 1, 0 ], [ 1, 2, 0 ] ],
    ),
);

for my $transform (@row_transforms) {
    is normalize_rows($transform->apply_puzzle($puzzle)), normalize_rows($puzzle),
        'band/row equivalent puzzle has the same row normal form';
}

my $digit_transform = Sudoku::Symmetry->new(
    digits => [ 9, 3, 7, 1, 8, 2, 6, 5, 4 ],
);
is normalize_rows($digit_transform->apply_puzzle($puzzle)), normalize_rows($puzzle),
    'digit-permuted puzzle has the same row normal form';

my $combined = $row_transforms[-1]->compose($digit_transform);
is normalize_rows($combined->apply_puzzle($puzzle)), normalize_rows($puzzle),
    'combined row and digit transform has the same row normal form';

for my $bad (undef, q{}, '0' x 80, ('0' x 80) . 'x') {
    my $ok = eval { Sudoku::Canonical->row_normal_form($bad); 1 };
    ok !$ok, 'invalid puzzle input is rejected';
    like $@, qr/(?:required|81 characters|digits 0 through 9)/,
        'invalid puzzle rejection has a useful error';
}

done_testing();
