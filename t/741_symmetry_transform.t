#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Symmetry;

my $puzzle =
    '123000000'
  . '000400000'
  . '000000500'
  . '600000000'
  . '000070000'
  . '000000008'
  . '000000090'
  . '000001000'
  . '000000000';

my $identity = Sudoku::Symmetry->identity;
ok $identity->is_identity, 'identity transform identifies itself';
is $identity->apply_puzzle($puzzle), $puzzle,
    'identity transform preserves puzzle exactly';
is $identity->serialize,
    'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
    'identity serialization is stable and compact';

my $digits = Sudoku::Symmetry->new(
    digits => [ 9, 8, 7, 6, 5, 4, 3, 2, 1 ],
);
is substr($digits->apply_puzzle($puzzle), 0, 3), '987',
    'digit permutation maps source digits to target digits';

my $rows = Sudoku::Symmetry->new(
    rows => [ [ 1, 0, 2 ], [ 0, 1, 2 ], [ 0, 1, 2 ] ],
);
is substr($rows->apply_puzzle($puzzle), 9, 3), '123',
    'row permutation moves rows within their source band';

my $cols = Sudoku::Symmetry->new(
    cols => [ [ 2, 1, 0 ], [ 0, 1, 2 ], [ 0, 1, 2 ] ],
);
is substr($cols->apply_puzzle($puzzle), 0, 3), '321',
    'column permutation moves columns within their source stack';

my $bands = Sudoku::Symmetry->new(bands => [ 2, 0, 1 ]);
is substr($bands->apply_puzzle($puzzle), 54, 3), '123',
    'band permutation moves the first source band to the third target band';

my $stacks = Sudoku::Symmetry->new(stacks => [ 1, 2, 0 ]);
is substr($stacks->apply_puzzle($puzzle), 3, 3), '123',
    'stack permutation moves the first source stack to the second target stack';

my $combined = Sudoku::Symmetry->new(
    digits => [ 2, 1, 3, 4, 5, 6, 7, 8, 9 ],
    bands  => [ 1, 2, 0 ],
    rows   => [ [ 2, 0, 1 ], [ 1, 2, 0 ], [ 0, 2, 1 ] ],
    stacks => [ 2, 0, 1 ],
    cols   => [ [ 1, 2, 0 ], [ 2, 0, 1 ], [ 0, 1, 2 ] ],
);
my $transformed = $combined->apply_puzzle($puzzle);
is length($transformed), 81, 'combined transform preserves puzzle length';
is clue_count($transformed), clue_count($puzzle),
    'combined transform preserves clue count';
like $combined->serialize,
    qr/\AD=213456789;B=120;R=201\|120\|021;S=201;C=120\|201\|012\z/,
    'combined transform has reproducible shorthand serialization';

my $copy = $combined->digits;
$copy->[0] = 9;
is $combined->digits->[0], 2, 'accessors return defensive copies';

for my $case (
    [ { digits => [ 1 .. 8, 8 ] }, qr/digit permutation/, 'duplicate digit is rejected' ],
    [ { bands  => [ 0, 0, 2 ] },  qr/band permutation/,  'invalid band permutation is rejected' ],
    [ { rows   => [ [ 0, 1, 2 ] ] }, qr/exactly three/, 'missing row permutations are rejected' ],
    [ { cols   => [ [ 0, 1, 3 ], [ 0, 1, 2 ], [ 0, 1, 2 ] ] }, qr/column permutations entry 1/, 'out-of-range column is rejected' ],
) {
    my ($args, $pattern, $name) = @$case;
    my $ok = eval { Sudoku::Symmetry->new(%$args); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name with useful error";
}

# Phase 2 inversion and composition guarantees.
my $inverse = $combined->inverse;
ok !$inverse->is_identity, 'inverse of a non-identity transform is non-identity';
is $inverse->apply_puzzle($combined->apply_puzzle($puzzle)), $puzzle,
    'inverse restores the exact original puzzle';
is $combined->apply_puzzle($inverse->apply_puzzle($puzzle)), $puzzle,
    'transform also restores input after applying its inverse first';
ok $combined->compose($inverse)->is_identity,
    'transform composed with its inverse is identity';
ok $inverse->compose($combined)->is_identity,
    'inverse composed with transform is identity';
ok $identity->inverse->is_identity, 'identity is its own inverse';

my $next = Sudoku::Symmetry->new(
    digits => [ 1, 3, 2, 4, 5, 6, 7, 9, 8 ],
    bands  => [ 2, 0, 1 ],
    rows   => [ [ 1, 0, 2 ], [ 2, 1, 0 ], [ 1, 2, 0 ] ],
    stacks => [ 1, 2, 0 ],
    cols   => [ [ 2, 0, 1 ], [ 1, 0, 2 ], [ 2, 1, 0 ] ],
);
my $composed = $combined->compose($next);
my $sequential = $next->apply_puzzle($combined->apply_puzzle($puzzle));
is $composed->apply_puzzle($puzzle), $sequential,
    'compose applies the receiver first and the argument second';
is clue_count($composed->apply_puzzle($puzzle)), clue_count($puzzle),
    'composed transform preserves clue count';
ok $combined->compose($identity)->equals($combined),
    'right composition with identity preserves transform';
ok $identity->compose($combined)->equals($combined),
    'left composition with identity preserves transform';
ok $combined->inverse->inverse->equals($combined),
    'double inversion restores the original transform';

my $compose_ok = eval { $combined->compose('not a transform'); 1 };
ok !$compose_ok, 'compose rejects non-transform arguments';
like $@, qr/another Sudoku::Symmetry transform/,
    'compose rejection has a useful error';

done_testing();
