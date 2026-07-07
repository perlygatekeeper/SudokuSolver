#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Deduction;

my $solver = Solver->new;
my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $cell = $grid->cell_from_row_column(0, 0);

my $set_value = Sudoku::Deduction->new(
    strategy    => 'Test Strategy',
    action      => 'set_value',
    cell        => $cell,
    value       => 5,
    explanation => 'Set the first cell to five.',
);

is(
    $solver->apply_deduction($grid, $set_value),
    1,
    'apply_deduction reports progress for set_value',
);

is($cell->value, 5, 'set_value deduction sets the cell value');
is($grid->solved, 1, 'set_value deduction increments solved count');
is($solver->deduction_count, 1, 'applied set_value deduction is recorded');
is($solver->deductions->[0], $set_value, 'set_value deduction is recorded in order');

is(
    $solver->apply_deduction($grid, $set_value),
    0,
    'set_value deduction reports no progress when cell is already solved',
);

is($solver->deduction_count, 1, 'no-progress set_value deduction is not recorded again');

my $candidate_cell = $grid->cell_from_row_column(0, 1);
ok($candidate_cell->possibilities->[7], 'candidate 7 begins present');

my $remove_candidate = Sudoku::Deduction->new(
    strategy => 'Test Strategy',
    action   => 'remove_candidate',
    cell     => $candidate_cell,
    value    => 7,
    reason   => 'Remove candidate 7 during test.',
);

is(
    $solver->apply_deduction($grid, $remove_candidate),
    1,
    'apply_deduction reports progress for remove_candidate',
);

ok(!$candidate_cell->possibilities->[7], 'remove_candidate deduction removes the candidate');
is($solver->deduction_count, 2, 'applied remove_candidate deduction is recorded');
is($solver->deductions->[1], $remove_candidate, 'remove_candidate deduction is recorded in order');

is(
    $solver->apply_deduction($grid, $remove_candidate),
    0,
    'remove_candidate reports no progress when candidate is already absent',
);

is($solver->deduction_count, 2, 'no-progress remove_candidate deduction is not recorded again');

my @batch = (
    Sudoku::Deduction->new(
        strategy => 'Batch Strategy',
        action   => 'remove_candidate',
        cell     => $candidate_cell,
        value    => 8,
    ),
    Sudoku::Deduction->new(
        strategy => 'Batch Strategy',
        action   => 'remove_candidate',
        cell     => $candidate_cell,
        value    => 9,
    ),
);

is(
    $solver->apply_deductions($grid, @batch),
    2,
    'apply_deductions returns total progress from a batch',
);

is($solver->deduction_count, 4, 'batch-applied deductions are recorded');
ok(!$candidate_cell->possibilities->[8], 'batch removes candidate 8');
ok(!$candidate_cell->possibilities->[9], 'batch removes candidate 9');

my $bad_grid = eval { $solver->apply_deduction('not a grid', $set_value); 1 };
ok(!$bad_grid, 'apply_deduction rejects non-Grid values');
like($@, qr/Grid object/, 'non-Grid error mentions Grid object');

my $bad_deduction = eval { $solver->apply_deduction($grid, 'not a deduction'); 1 };
ok(!$bad_deduction, 'apply_deduction rejects non-deduction values');
like($@, qr/Sudoku::Deduction/, 'non-deduction error mentions Sudoku::Deduction');

my $unknown_action = Sudoku::Deduction->new(
    strategy => 'Bad Strategy',
    action   => 'unknown_action',
    cell     => $candidate_cell,
);

my $bad_action = eval { $solver->apply_deduction($grid, $unknown_action); 1 };
ok(!$bad_action, 'apply_deduction rejects unknown actions');
like($@, qr/Unknown deduction action/, 'unknown-action error names the problem');

is($solver->deduction_count, 4, 'failed applications are not recorded');

done_testing();
