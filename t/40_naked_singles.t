#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Deduction;
use Sudoku::Strategy::NakedSingles;
use Sudoku::Test qw(capture_stdout);

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $cell = $grid->cell_from_row_column(0, 0);

for my $value (1 .. 8) {
    ok($cell->remove_possibility($value), "removed $value from target cell");
}

is($cell->possibilities->[0], 1, 'target cell has one possibility left');
ok($cell->possibilities->[9], 'target cell still has 9 as a possibility');
is($grid->solved, 0, 'empty grid starts with no solved cells');

my @deductions;
my $strategy_output = capture_stdout {
    @deductions = Sudoku::Strategy::NakedSingles->new->apply($grid);
};

is(scalar @deductions, 1, 'Naked Singles strategy returns one deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($deductions[0]->strategy, 'Naked Singles', 'deduction records the strategy name');
is($deductions[0]->action, 'set_value', 'deduction action sets a value');
is($deductions[0]->cell, $cell, 'deduction records the target cell');
is($deductions[0]->value, 9, 'deduction records the value to set');
is($cell->value, 0, 'strategy discovery does not directly set the cell');
is($grid->solved, 0, 'strategy discovery does not update the solved count');
like($strategy_output, qr/Looking for Naked Singles/, 'direct strategy announces Naked Singles search');

my $progress;
my $output = capture_stdout {
    $progress = $grid->find_and_set_naked_singles;
};

is($progress, 1, 'find_and_set_naked_singles reports one Naked Single solved cell');
like($output, qr/Looking for Naked Singles/, 'strategy announces Naked Singles search');
is($grid->solved, 1, 'solved count increments after naked single is set');
is($cell->value, 9, 'Naked Single value is assigned to the cell');
is_deeply(
    $cell->possibilities,
    [ (0) x 10 ],
    'assigned Naked Single has no remaining possibilities',
);

for my $mate (@{ $grid->row_mates_of($cell) }) {
    ok(!$mate->possibilities->[9], 'Naked Single value removed from row mate');
}

for my $mate (@{ $grid->column_mates_of($cell) }) {
    ok(!$mate->possibilities->[9], 'Naked Single value removed from column mate');
}

for my $mate (@{ $grid->box_mates_of($cell) }) {
    ok(!$mate->possibilities->[9], 'Naked Single value removed from box mate');
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[9], 'Naked Single value remains possible in unrelated cell');

done_testing();
