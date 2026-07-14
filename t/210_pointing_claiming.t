#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Test qw(capture_stdout);

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Force value 7 in box 0 to appear only in row 0.  This is the
# called pointing/claiming.
for my $row (1, 2) {
    for my $column (0, 1, 2) {
        my $cell = $grid->cell_from_row_column($row, $column);
        ok($cell->remove_possibility(7), "removed 7 from box cell r$row c$column");
    }
}

for my $column (0, 1, 2) {
    ok(
        $grid->cell_from_row_column(0, $column)->possibilities->[7],
        "7 remains possible in row 0 box 0 column $column",
    );
}

for my $column (3 .. 8) {
    ok(
        $grid->cell_from_row_column(0, $column)->possibilities->[7],
        "7 begins possible in row 0 outside box 0 column $column",
    );
}

my $progress;
my $output = capture_stdout {
    $progress = $grid->find_pointing_claiming;
};

is($progress, 6, 'find_pointing_claiming applies Pointing / Claiming and removes six outside-row possibilities');

for my $column (0, 1, 2) {
    ok(
        $grid->cell_from_row_column(0, $column)->possibilities->[7],
        "7 remains possible inside the pointing box at column $column",
    );
}

for my $column (3 .. 8) {
    ok(
        !$grid->cell_from_row_column(0, $column)->possibilities->[7],
        "7 removed from row 0 outside box 0 at column $column",
    );
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[7], '7 remains possible in unrelated cell');

done_testing();
