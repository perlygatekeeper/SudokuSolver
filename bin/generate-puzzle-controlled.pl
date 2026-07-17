#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use lib 'lib';
use Sudoku::Generator;

my $generated = Sudoku::Generator->new->controlled_reveals(
    corpus_seed   => 20260717,
    symmetry_seed => 12345,
    reveal_seed   => 67890,
    clue_count    => 30,
    criteria      => { difficulty => 'Master' },
);

my $puzzle   = $generated->puzzle;
my $solution = $generated->solution;

say $puzzle;
say $solution;
