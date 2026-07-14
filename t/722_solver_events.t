#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 'lib';

use Solver;
use Sudoku::Deduction;

my $solver = Solver->new;

can_ok($solver, qw(event_log events clear_events record_event));
is_deeply($solver->events, [], 'solver event log starts empty');

my $event = $solver->record_event('pass_started', pass => 1);
is($event->sequence, 1, 'solver records sequenced events');
is($solver->events->[0]->type, 'pass_started', 'solver exposes recorded events');

my $deduction = Sudoku::Deduction->new(
    strategy => 'Test Strategy',
    action   => 'set_value',
    row      => 0,
    column   => 0,
    value    => 5,
);
$solver->record_deduction($deduction);

my $events = $solver->events;
is($events->[-1]->type, 'deduction', 'recorded deductions emit deduction events');
is(
    $events->[-1]->data->{strategy},
    'Test Strategy',
    'deduction event contains structured deduction data',
);

is($solver->clear_events, $solver, 'clear_events returns solver');
is_deeply($solver->events, [], 'clear_events empties solver event log');

done_testing();
