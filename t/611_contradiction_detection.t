#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Contradiction;
use Sudoku::Deduction;

my $solver = Solver->new;
my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $cell = $grid->cell_from_row_column(0, 0);
$cell->possibilities([ (0) x 10 ]);
$cell->value(0);

my $contradiction = $solver->check_contradiction($grid);
isa_ok($contradiction, 'Sudoku::Contradiction');
is($contradiction->kind, 'zero_candidates', 'zero-candidate contradiction is identified');
is($contradiction->cell, $cell, 'zero-candidate contradiction records the cell');
is($solver->status, 'contradiction', 'solver status records contradiction');
ok($solver->has_contradiction, 'solver stores contradiction object');
like($solver->contradiction->summary, qr/zero_candidates/, 'summary includes contradiction kind');

$solver->reset_status;
is($solver->status, 'ready', 'reset_status restores ready state');
ok(!$solver->has_contradiction, 'reset_status clears contradiction object');

my $duplicate_grid = Grid->new;
$duplicate_grid->load_from_string('110' . ('0' x 78));

my $duplicate = $solver->check_contradiction($duplicate_grid);
isa_ok($duplicate, 'Sudoku::Contradiction');
is($duplicate->kind, 'duplicate_value', 'duplicate-value contradiction is identified');
is($duplicate->value, 1, 'duplicate-value contradiction records the repeated value');
is($duplicate->unit, 'row 1', 'duplicate-value contradiction records the unit');
is(scalar @{ $duplicate->cells }, 2, 'duplicate-value contradiction records both cells');

my $apply_grid = Grid->new;
$apply_grid->load_from_string('0' x 81);
my $apply_cell = $apply_grid->cell_from_row_column(0, 0);
$apply_cell->possibilities([ 1, 0, 0, 0, 0, 0, 0, 0, 0, 9 ]);

$solver->reset_status;
my $remove_last_candidate = Sudoku::Deduction->new(
    strategy => 'Contradiction Test',
    action   => 'remove_candidate',
    cell     => $apply_cell,
    value    => 9,
);

is(
    $solver->apply_deduction($apply_grid, $remove_last_candidate),
    1,
    'removing the last candidate reports progress',
);

is($solver->status, 'contradiction', 'removing the last candidate marks contradiction');
is($solver->contradiction->kind, 'zero_candidates', 'last-candidate removal creates zero-candidate contradiction');

my $step_grid = Grid->new;
$step_grid->load_from_string('110' . ('0' x 78));
$solver->reset_status;
my $deduction = $solver->step($step_grid);
ok(!defined $deduction, 'step returns no deduction when puzzle is already contradictory');
is($solver->status, 'contradiction', 'step records contradiction before applying strategies');

my $ok_grid = Grid->new;
$ok_grid->load_from_string('0' x 81);
$solver->reset_status;
ok(!$solver->check_contradiction($ok_grid), 'empty grid has no contradiction');
is($solver->status, 'ready', 'status remains ready when no contradiction is found');

done_testing();
