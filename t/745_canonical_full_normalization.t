use strict;
use warnings;

use Test::More;
use lib '.';

use Sudoku::Canonical qw(canonicalize);
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

my $result = Sudoku::Canonical->canonical_form($puzzle);
is $result->stage, 'canonical',
    'full canonical form identifies its stage';
is length($result->puzzle), 81,
    'canonical form remains an 81-character puzzle';
is $result->transform->apply_puzzle($puzzle), $result->puzzle,
    'recorded transform produces the canonical puzzle';
is $result->transform->inverse->apply_puzzle($result->puzzle), $puzzle,
    'recorded transform restores the exact original puzzle';

is canonicalize($result->puzzle), $result->puzzle,
    'full canonization is idempotent';

for my $seed (1, 384729184) {
    my $transform = Sudoku::Symmetry->random(seed => $seed);
    is canonicalize($transform->apply_puzzle($puzzle)), $result->puzzle,
        "full canonization is invariant under seeded symmetry $seed";
}

for my $bad (undef, q{}, '0' x 80, ('0' x 80) . 'x') {
    my $ok = eval { Sudoku::Canonical->canonical_form($bad); 1 };
    ok !$ok, 'invalid puzzle input is rejected';
    like $@, qr/(?:required|81 characters|digits 0 through 9)/,
        'invalid puzzle rejection has a useful error';
}

done_testing();
