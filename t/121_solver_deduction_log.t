#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Deduction;

my $solver = Solver->new;

can_ok(
    $solver,
    qw(
        deductions
        record_deduction
        clear_deductions
        deduction_count
    ),
);

is_deeply($solver->deductions, [], 'deduction log starts empty');
is($solver->deduction_count, 0, 'deduction count starts at zero');

my $deduction = Sudoku::Deduction->new(
    strategy    => 'Test Strategy',
    action      => 'set_value',
    row         => 0,
    column      => 1,
    value       => 5,
    explanation => 'Test deduction for solver log.',
);

is(
    $solver->record_deduction($deduction),
    $deduction,
    'record_deduction returns the recorded deduction',
);

is($solver->deduction_count, 1, 'deduction count reflects one recorded deduction');
is_deeply($solver->deductions, [$deduction], 'deduction log contains the recorded deduction');

my $second = Sudoku::Deduction->new(
    strategy => 'Another Strategy',
    action   => 'remove_candidate',
    row      => 2,
    column   => 3,
    value    => 8,
);

$solver->record_deduction($second);
is($solver->deduction_count, 2, 'multiple deductions may be recorded');
is_deeply($solver->deductions, [$deduction, $second], 'deduction order is preserved');

my $bad_record = eval { $solver->record_deduction('not a deduction'); 1 };
ok(!$bad_record, 'record_deduction rejects non-deduction values');
like($@, qr/Sudoku::Deduction/, 'record_deduction reports the expected type requirement');

is($solver->clear_deductions, $solver, 'clear_deductions returns the solver for chaining');
is_deeply($solver->deductions, [], 'clear_deductions empties the log');
is($solver->deduction_count, 0, 'deduction count returns to zero after clearing');

my $other_solver = Solver->new;
is_deeply($other_solver->deductions, [], 'new solver gets an independent deduction log');

$other_solver->record_deduction($deduction);
is($solver->deduction_count, 0, 'cleared solver log is not affected by another solver');
is($other_solver->deduction_count, 1, 'other solver has its own deduction log');

done_testing();
