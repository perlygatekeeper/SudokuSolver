#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Hypothetical;
use Sudoku::Hypothetical::Result;

sub set_candidates {
    my ($cell, @values) = @_;

    my @possibilities = (0) x 10;
    $possibilities[$_] = $_ for @values;
    $possibilities[0] = scalar @values;
    $cell->value(0);
    $cell->possibilities(\@possibilities);

    return $cell;
}

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $source = $grid->cell_from_row_column(0, 0);
set_candidates($source, 1, 2);

my $before_string = $grid->as_puzzle_string;
my @before_candidates = @{ $source->possibilities };

my $result = Sudoku::Hypothetical->new(
    grid             => $grid,
    row              => 0,
    column           => 0,
    value            => 1,
    assumption       => 'off',
    max_steps        => 20,
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
)->run;

isa_ok($result, 'Sudoku::Hypothetical::Result');
is($result->status, 'fixed_point', 'branch reaches a deterministic fixed point');
is($result->grid->cell_from_row_column(0, 0)->value, 2,
    'OFF assumption leaves a naked single that is propagated');
is(scalar @{ $result->placements }, 1, 'propagated placement is reported');
is(scalar @{ $result->eliminations }, 0, 'assumption removal is not reported as a propagated elimination');
is($result->history->[0]{kind}, 'assumption', 'history begins with the temporary assumption');
is($result->history->[1]{strategy}, 'Naked Singles', 'history records the propagation strategy');

is($grid->as_puzzle_string, $before_string, 'original grid values remain unchanged');
is_deeply($source->possibilities, \@before_candidates,
    'original grid candidate state remains unchanged');
isnt($result->grid, $grid, 'hypothetical result contains a cloned grid');
isnt($result->grid->cells->[0], $grid->cells->[0], 'cloned grid has independent cells');

my $on_grid = Grid->new;
$on_grid->load_from_string('0' x 81);
set_candidates($on_grid->cell_from_row_column(0, 0), 4, 5);

my $on_result = Sudoku::Hypothetical->new(
    grid             => $on_grid,
    row              => 0,
    column           => 0,
    value            => 4,
    assumption       => 'on',
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
)->run;

is($on_result->grid->cell_from_row_column(0, 0)->value, 4,
    'ON assumption temporarily sets the candidate');
is($on_grid->cell_from_row_column(0, 0)->value, 0,
    'ON assumption does not alter the source grid');

my $bad_grid = Grid->new;
$bad_grid->load_from_string('0' x 81);
set_candidates($bad_grid->cell_from_row_column(0, 0), 1, 2);

my $bad_result = Sudoku::Hypothetical->new(
    grid             => $bad_grid,
    row              => 0,
    column           => 0,
    value            => 9,
    assumption       => 'on',
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
)->run;

is($bad_result->status, 'contradiction', 'unavailable ON assumption is a contradiction');
ok($bad_result->has_contradiction, 'contradiction result carries a structured contradiction');
is($bad_result->contradiction->kind, 'assumption_candidate_absent',
    'contradiction identifies an absent assumed candidate');

my $limit_grid = Grid->new;
$limit_grid->load_from_string('0' x 81);
set_candidates($limit_grid->cell_from_row_column(0, 0), 1);
set_candidates($limit_grid->cell_from_row_column(4, 4), 2);

my $limit_result = Sudoku::Hypothetical->new(
    grid             => $limit_grid,
    row              => 8,
    column           => 8,
    value            => 9,
    assumption       => 'off',
    max_steps        => 1,
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
)->run;

is($limit_result->status, 'limit', 'propagation stops at the configured step limit');
is($limit_result->steps, 1, 'result records the number of propagated steps');
ok($limit_result->reached_limit, 'result exposes a limit predicate');

my $solver = Solver->new(
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
    output_mode      => 'quiet',
);
my $fixed_grid = Grid->new;
$fixed_grid->load_from_string('0' x 81);
my $summary = $solver->propagate($fixed_grid, max_steps => 5);

is($summary->{status}, 'fixed_point', 'Solver propagate reports a fixed point');
is($summary->{steps}, 0, 'Solver propagate reports zero steps without deductions');
is_deeply($summary->{history}, [], 'Solver propagate returns an empty history without deductions');

my $invalid = eval {
    Sudoku::Hypothetical->new(
        grid       => $grid,
        row        => 0,
        column     => 0,
        value      => 1,
        assumption => 'maybe',
    );
    1;
};
ok(!$invalid, 'invalid assumption mode is rejected');
like($@, qr/assumption must be 'on' or 'off'/, 'invalid mode error is descriptive');

done_testing();
