#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::HiddenPairs;
use Sudoku::Test qw(capture_stdout);

sub values_left {
    my ($cell) = @_;
    return [ grep { $cell->possibilities->[$_] } 1 .. 9 ];
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $first  = $grid->cell_from_row_column(0, 0);
my $second = $grid->cell_from_row_column(0, 3);

# Make 2 and 5 appear only in these two cells in row 0.  Those two
# values form a hidden pair and should eliminate all other candidates
# from the pair cells.
for my $column (1, 2, 4 .. 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok($cell->remove_possibility(2), "removed 2 from row cell column $column");
    ok($cell->remove_possibility(5), "removed 5 from row cell column $column");
}

is_deeply(values_left($first),  [ 1 .. 9 ], 'first hidden-pair cell starts with all candidates');
is_deeply(values_left($second), [ 1 .. 9 ], 'second hidden-pair cell starts with all candidates');

my $progress;
my @deductions;
my $output = capture_stdout {
    @deductions = Sudoku::Strategy::HiddenPairs->new->apply($grid);
    $progress = $grid->apply_deductions(@deductions);
};

is(scalar @deductions, 14, 'HiddenPairs returns candidate-removal deductions for both pair cells');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($progress, 14, 'applying HiddenPairs deductions removes all non-pair candidates');
like($output, qr/Looking for Hidden Pairs/, 'strategy announces hidden pair search');
like($output, qr/Hidden pair \(row\)/, 'strategy finds the row-based hidden pair');

is_deeply(values_left($first), [ 2, 5 ], 'first hidden-pair cell keeps only the pair values');

is_deeply(values_left($second), [ 2, 5 ], 'second hidden-pair cell keeps only the pair values');

for my $column (1, 2, 4 .. 8) {
    my $cell = $grid->cell_from_row_column(0, $column);
    ok(!$cell->possibilities->[2], "2 remains absent from non-pair row cell column $column");
    ok(!$cell->possibilities->[5], "5 remains absent from non-pair row cell column $column");
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[2], '2 remains possible in unrelated cell');
ok($unrelated->possibilities->[5], '5 remains possible in unrelated cell');

done_testing();
