#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use lib 'lib';
use Sudoku::Generator;

my $generated = Sudoku::Generator->new->symmetry_randomized(
    corpus_seed   => 20260717,
    symmetry_seed => 12345,
    criteria      => { difficulty => 'Master' },
);

say 'Puzzle:        ' . $generated->puzzle;
say 'Solution:      ' . $generated->solution;
say 'Canonical ID:  ' . $generated->canonical_id;
say 'Transform:     ' . $generated->transform_shorthand;
