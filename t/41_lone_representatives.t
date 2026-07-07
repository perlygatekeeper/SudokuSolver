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

my @deductions;
my $strategy_output = capture_stdout {
    @deductions = Sudoku::Strategy::HiddenSingles->new->apply($grid);
};

is(scalar @deductions, 1, 'Hidden Singles strategy returns one deduction');
isa_ok($deductions[0], 'Sudoku::Deduction');
is($deductions[0]->strategy, 'Hidden Singles', 'deduction records the strategy name');
is($deductions[0]->action, 'set_value', 'deduction action sets a value');
is($deductions[0]->cell, $target, 'deduction records the target cell');
is($deductions[0]->value, 5, 'deduction records the value to set');
is($target->value, 0, 'strategy discovery does not directly set the cell');
is($grid->solved, 0, 'strategy discovery does not update the solved count');
like($strategy_output, qr/Looking for Lone representatives/, 'direct strategy announces lone representative search');

my $progress;
my $output = capture_stdout {
    $progress = $grid->find_and_set_lone_representatives;
};

is($progress, 1, 'find_and_set_lone_representatives reports one solved cell');
like($output, qr/Looking for Lone representatives/, 'strategy announces lone representative search');
is($target->value, 5, 'lone representative value is assigned');
is($grid->solved, 1, 'solved count increments after lone representative is set');
is_deeply(
    $target->possibilities,
    [ (0) x 10 ],
    'assigned lone representative has no remaining possibilities',
);

for my $mate (@{ $grid->row_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'lone representative value removed from row mate');
}

for my $mate (@{ $grid->column_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'lone representative value removed from column mate');
}

for my $mate (@{ $grid->box_mates_of($target) }) {
    ok(!$mate->possibilities->[5], 'lone representative value removed from box mate');
}

my $unrelated = $grid->cell_from_row_column(8, 8);
ok($unrelated->possibilities->[5], 'lone representative value remains possible in unrelated cell');

done_testing();
