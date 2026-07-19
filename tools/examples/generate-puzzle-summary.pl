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

say 'Puzzle:        ' . $generated->puzzle;
say 'Solution:      ' . $generated->solution;
say 'Canonical ID:  ' . $generated->canonical_id;
say 'Transform:     ' . $generated->transform_shorthand;
say 'Reveal cells:  ' . join ',', @{ $generated->reveal_cells };
