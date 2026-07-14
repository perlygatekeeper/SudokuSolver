#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Deduction;
use Sudoku::Strategy::HiddenSingles;
use Sudoku::Test qw(capture_stdout);

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

my $target = $grid->cell_from_row_column(0, 4);

for my $column (0 .. 8) {
    next if $column == 4;

    my $cell = $grid->cell_from_row_column(0, $column);
    ok($cell->remove_possibility(5), "removed 5 from row cell column $column");
}

ok($target->possibilities->[5], 'target cell still allows the hidden single value');
is($grid->solved, 0, 'empty grid starts with no solved cells');

my @deductions = Sudoku::Strategy::HiddenSingles->new->apply($grid);

is(scalar @deductions, 1, 'Hidden Singles strategy returns one deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($deductions[0]->strategy, 'Hidden Singles', 'deduction records the strategy name');
is($deductions[0]->action, 'set_value', 'deduction action sets a value');
is($deductions[0]->cell, $target, 'deduction records the target cell');
is($deductions[0]->value, 5, 'deduction records the value to set');
is($target->value, 0, 'strategy discovery does not directly set the cell');
is($grid->solved, 0, 'strategy discovery does not update the solved count');
my $progress;
my $output = capture_stdout {
    $progress = $grid->find_and_set_hidden_singles;
};

is($progress, 1, 'find_and_set_hidden_singles reports one Hidden Single solved cell');
is($target->value, 5, 'Hidden Single value is assigned');
is($grid->solved, 1, 'solved count increments after Hidden Single is set');
is_deeply(
    $target->possibilities,
    [ (0) x 10 ],
    'assigned Hidden Single has no remaining possibilities',
);

for my $mate (@{ $grid->row_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'Hidden Single value removed from row mate');
}

for my $mate (@{ $grid->column_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'Hidden Single value removed from column mate');
}

for my $mate (@{ $grid->box_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'Hidden Single value removed from box mate');
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[5], 'Hidden Single value remains possible in unrelated cell');

done_testing();
