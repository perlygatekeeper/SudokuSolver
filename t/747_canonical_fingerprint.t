use strict;
use warnings;

use Test::More;
use lib 'lib';

use Sudoku::Canonical qw(canonical_fingerprint canonicalize);
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

my $canonical =
      '000000001'
    . '000000020'
    . '000003000'
    . '000040500'
    . '006000300'
    . '007810000'
    . '010020004'
    . '030000070'
    . '950000000';

my $fingerprint = '196572-2875-365782-4579-4792-53-6388-64-91';

is canonicalize($puzzle), $canonical,
    'fixture still maps to the established canonical representative';

is canonical_fingerprint($puzzle), $fingerprint,
    'canonical fingerprint is the coordinate encoding of the canonical puzzle';

is length(canonical_fingerprint($puzzle)), 42,
    'a canonical 17-clue fingerprint is 42 characters';

for my $seed (1, 3, 19, 384729184, 4294967295) {
    my $transform = Sudoku::Symmetry->random(seed => $seed);
    is canonical_fingerprint($transform->apply_puzzle($puzzle)), $fingerprint,
        "canonical fingerprint is symmetry-invariant for seed $seed";
}

my $result = Sudoku::Canonical->canonical_form($puzzle);
is $result->coordinate_encoding, $fingerprint,
    'canonical result exposes its coordinate encoding';
is $result->fingerprint, $fingerprint,
    'canonical result exposes its canonical fingerprint';

my $digit_result = Sudoku::Canonical->digit_normal_form($puzzle);
my $error = q{};
eval { $digit_result->fingerprint; 1 } or $error = $@;
like $error, qr/only for a canonical result/,
    'non-canonical intermediate results cannot claim a fingerprint';

done_testing();
