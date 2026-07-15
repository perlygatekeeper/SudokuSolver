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

my $expected =
      '000000001'
    . '000000020'
    . '000003000'
    . '000040500'
    . '006000300'
    . '007810000'
    . '010020004'
    . '030000070'
    . '950000000';

is canonicalize($puzzle), $expected,
    'first-row pruning preserves the established canonical representative';

for my $seed (3, 19, 384729184) {
    my $transform = Sudoku::Symmetry->random(seed => $seed);
    is canonicalize($transform->apply_puzzle($puzzle)), $expected,
        "pruned canonization remains symmetry-invariant for seed $seed";
}

is canonicalize($expected), $expected,
    'pruned canonization remains idempotent';

done_testing();
