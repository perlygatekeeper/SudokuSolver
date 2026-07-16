#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';
use Sudoku::PatternSymmetry qw(pattern_symmetries);

sub puzzle_from_clues {
    my (@coordinates) = @_;
    my @cells = ('0') x 81;
    my $digit = 1;
    for my $coordinate (@coordinates) {
        my ($row, $column) = @{$coordinate};
        $cells[($row - 1) * 9 + ($column - 1)] = $digit;
        $digit = $digit == 9 ? 1 : $digit + 1;
    }
    return join q{}, @cells;
}

my $asymmetric_symmetries =
    pattern_symmetries(puzzle_from_clues([1, 1], [2, 3], [4, 5]));
is_deeply(
    $asymmetric_symmetries,
    [],
    'asymmetric clue mask has no documented pattern symmetries',
);

my %fixtures = (
    'rotation-180' => puzzle_from_clues(
        [1, 2], [9, 8], [2, 4], [8, 6],
    ),
    'rotation-90' => puzzle_from_clues(
        [1, 2], [2, 9], [9, 8], [8, 1],
    ),
    'reflection-horizontal' => puzzle_from_clues(
        [1, 2], [9, 2], [3, 7], [7, 7],
    ),
    'reflection-vertical' => puzzle_from_clues(
        [1, 2], [1, 8], [6, 3], [6, 7],
    ),
    'reflection-main-diagonal' => puzzle_from_clues(
        [1, 4], [4, 1], [7, 9], [9, 7],
    ),
    'reflection-anti-diagonal' => puzzle_from_clues(
        [1, 4], [6, 9], [2, 2], [8, 8],
    ),
);

for my $symmetry (sort keys %fixtures) {
    my %seen = map { $_ => 1 } @{ pattern_symmetries($fixtures{$symmetry}) };
    ok $seen{$symmetry}, "$symmetry is detected";
}

my $bad = eval { pattern_symmetries(('0' x 80) . '.'); 1 };
ok !$bad, 'pattern symmetry analysis rejects non-normalized puzzles';
like $@, qr/only digits 0 through 9/, 'rejection has useful validation error';

done_testing();
