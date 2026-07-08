#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::RemotePairs;
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
my $second = set_possibilities($grid->cell_from_row_column(3, 4), 2, 5);

is_deeply(
    $first->possibilities,
    [ 2, 0, 2, 0, 0, 5, 0, 0, 0, 0 ],
    'first remote-pair candidate contains only 2 and 5',
);

is_deeply(
    $second->possibilities,
    [ 2, 0, 2, 0, 0, 5, 0, 0, 0, 0 ],
    'second remote-pair candidate contains only 2 and 5',
);

my $upper_intersection = $grid->cell_from_row_column(0, 4);
my $lower_intersection = $grid->cell_from_row_column(3, 0);

for my $cell ($upper_intersection, $lower_intersection) {
    ok($cell->possibilities->[2], '2 begins possible in remote-pair intersection');
    ok($cell->possibilities->[5], '5 begins possible in remote-pair intersection');
}

my $progress;
my @deductions;
my $output = capture_stdout {
    @deductions = Sudoku::Strategy::RemotePairs->new->apply($grid);
    $progress = $grid->apply_deductions(@deductions);
};

# This records the current legacy behavior.  The project notes say the
# remote-pairs logic is based on an incomplete understanding of the
# technique, so future work may replace this contract intentionally.
is(scalar @deductions, 4, 'RemotePairs returns two candidate removals for two intersections');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($progress, 4, 'applying RemotePairs deductions removes two candidates from two intersections');

ok($first->possibilities->[2],  '2 remains possible in first remote-pair candidate');
ok($first->possibilities->[5],  '5 remains possible in first remote-pair candidate');
ok($second->possibilities->[2], '2 remains possible in second remote-pair candidate');
ok($second->possibilities->[5], '5 remains possible in second remote-pair candidate');

for my $cell ($upper_intersection, $lower_intersection) {
    ok(!$cell->possibilities->[2], '2 removed from remote-pair intersection');
    ok(!$cell->possibilities->[5], '5 removed from remote-pair intersection');
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[2], '2 remains possible in unrelated cell');
ok($unrelated->possibilities->[5], '5 remains possible in unrelated cell');

done_testing();
