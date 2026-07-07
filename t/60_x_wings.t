#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::XWing;
use Sudoku::Test qw(capture_stdout);

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Construct a row-based X-Wing for value 4.  In rows 0 and 3,
# value 4 appears only in columns 1 and 6.  The strategy should
# remove 4 from the other cells in those two columns.
for my $row (0, 3) {
    for my $column (0 .. 8) {
        next if $column == 1 || $column == 6;
        ok(
            $grid->cell_from_row_column($row, $column)->remove_possibility(4),
            "removed 4 from X-Wing row $row column $column",
        );
    }
}

for my $row (0, 3) {
    for my $column (1, 6) {
        ok(
            $grid->cell_from_row_column($row, $column)->possibilities->[4],
            "4 remains possible in X-Wing corner row $row column $column",
        );
    }
}

for my $row (1, 2, 4 .. 8) {
    for my $column (1, 6) {
        ok(
            $grid->cell_from_row_column($row, $column)->possibilities->[4],
            "4 begins possible in elimination target row $row column $column",
        );
    }
}

my $progress;
my @deductions;
my $output = capture_stdout {
    @deductions = Sudoku::Strategy::XWing->new->apply($grid);
    $progress = $grid->apply_deductions(@deductions);
};

is(scalar @deductions, 14, 'XWing returns fourteen candidate-removal deductions');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($progress, 14, 'applying XWing deductions removes fourteen candidates from two columns');
like($output, qr/Looking for X-Wing/, 'strategy announces X-Wing search');
like($output, qr/row-based X-wing/, 'strategy finds the row-based X-Wing');

for my $row (0, 3) {
    for my $column (1, 6) {
        ok(
            $grid->cell_from_row_column($row, $column)->possibilities->[4],
            "4 remains possible in X-Wing corner row $row column $column",
        );
    }
}

for my $row (1, 2, 4 .. 8) {
    for my $column (1, 6) {
        ok(
            !$grid->cell_from_row_column($row, $column)->possibilities->[4],
            "4 removed from X-Wing column target row $row column $column",
        );
    }
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[4], '4 remains possible in unrelated cell');

done_testing();
