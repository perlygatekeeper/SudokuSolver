use strict;
use warnings;

use Test::More;
use lib '.';

use Sudoku::Canonical qw(normalize_columns);
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

my $result = Sudoku::Canonical->column_normal_form($puzzle);
is $result->stage, 'column-normal',
    'column normal form identifies its normalization stage';
is length($result->puzzle), 81,
    'column normal form remains an 81-character puzzle';
is $result->transform->apply_puzzle($puzzle), $result->puzzle,
    'recorded transform produces the column-normal puzzle';
is $result->transform->inverse->apply_puzzle($result->puzzle), $puzzle,
    'recorded transform is invertible';

is normalize_columns(normalize_columns($puzzle)), normalize_columns($puzzle),
    'column normalization is idempotent';

my @column_transforms = (
    Sudoku::Symmetry->new(stacks => [ 2, 0, 1 ]),
    Sudoku::Symmetry->new(cols => [ [ 2, 0, 1 ], [ 1, 2, 0 ], [ 0, 2, 1 ] ]),
    Sudoku::Symmetry->new(
        stacks => [ 1, 2, 0 ],
        cols   => [ [ 1, 0, 2 ], [ 2, 1, 0 ], [ 1, 2, 0 ] ],
    ),
);

for my $transform (@column_transforms) {
    is normalize_columns($transform->apply_puzzle($puzzle)), normalize_columns($puzzle),
        'stack/column equivalent puzzle has the same column normal form';
}

my $digit_transform = Sudoku::Symmetry->new(
    digits => [ 9, 3, 7, 1, 8, 2, 6, 5, 4 ],
);
is normalize_columns($digit_transform->apply_puzzle($puzzle)), normalize_columns($puzzle),
    'digit-permuted puzzle has the same column normal form';

my $combined = $column_transforms[-1]->compose($digit_transform);
is normalize_columns($combined->apply_puzzle($puzzle)), normalize_columns($puzzle),
    'combined column and digit transform has the same column normal form';

for my $bad (undef, q{}, '0' x 80, ('0' x 80) . 'x') {
    my $ok = eval { Sudoku::Canonical->column_normal_form($bad); 1 };
    ok !$ok, 'invalid puzzle input is rejected';
    like $@, qr/(?:required|81 characters|digits 0 through 9)/,
        'invalid puzzle rejection has a useful error';
}

done_testing();
