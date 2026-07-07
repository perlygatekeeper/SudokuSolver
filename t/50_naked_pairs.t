#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Test qw(capture_stdout);

sub set_possibilities {
    my ($cell, @values) = @_;

    my %keep = map { $_ => 1 } @values;

    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $first  = set_possibilities($grid->cell_from_row_column(0, 0), 2, 5);
my $second = set_possibilities($grid->cell_from_row_column(0, 3), 2, 5);

is_deeply(
    $first->possibilities,
    [ 2, 0, 2, 0, 0, 5, 0, 0, 0, 0 ],
    'first naked-pair cell contains only 2 and 5',
);

is_deeply(
    $second->possibilities,
    [ 2, 0, 2, 0, 0, 5, 0, 0, 0, 0 ],
    'second naked-pair cell contains only 2 and 5',
);

for my $column (1, 2, 4 .. 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok($cell->possibilities->[2], "2 begins possible in row mate column $column");
    ok($cell->possibilities->[5], "5 begins possible in row mate column $column");
}

my $progress;
my $output = capture_stdout {
    $progress = $grid->find_naked_pairs;
};

is($progress, 14, 'find_naked_pairs removes two candidates from seven row mates');
like($output, qr/Looking for Naked Pairs/, 'strategy announces naked pair search');

ok($first->possibilities->[2],  '2 remains possible in first naked-pair cell');
ok($first->possibilities->[5],  '5 remains possible in first naked-pair cell');
ok($second->possibilities->[2], '2 remains possible in second naked-pair cell');
ok($second->possibilities->[5], '5 remains possible in second naked-pair cell');

for my $column (1, 2, 4 .. 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok(!$cell->possibilities->[2], "2 removed from row mate column $column");
    ok(!$cell->possibilities->[5], "5 removed from row mate column $column");
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[2], '2 remains possible in unrelated cell');
ok($unrelated->possibilities->[5], '5 remains possible in unrelated cell');

done_testing();
