#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 'lib';

use Sudoku::Render::Event;
use Sudoku::Render::EventLog;

my @types = Sudoku::Render::Event->known_types;
ok(grep($_ eq 'deduction', @types), 'deduction is a known event type');
ok(grep($_ eq 'final_status', @types), 'final_status is a known event type');

my $event = Sudoku::Render::Event->new(
    type => 'pass_started',
    data => { pass => 1 },
);

is($event->schema_version, 1, 'event schema is versioned');
is($event->type, 'pass_started', 'event type is available');
is_deeply($event->data, { pass => 1 }, 'event data is available');
ok(!defined $event->sequence, 'unrecorded event has no sequence');

my $copy = $event->data;
$copy->{pass} = 99;
is_deeply($event->data, { pass => 1 }, 'event data is defensively copied');

my $log = Sudoku::Render::EventLog->new;
is($log->count, 0, 'event log starts empty');

my $first = $log->record($event);
is($first->sequence, 1, 'first recorded event receives sequence 1');

my $second = $log->record(
    'strategy_result',
    strategy => 'Hidden Singles',
    count    => 1,
);
is($second->sequence, 2, 'second event receives sequence 2');
is($log->count, 2, 'event count is tracked');

my $events = $log->events;
is(scalar @$events, 2, 'events returns every event');
is($events->[1]->type, 'strategy_result', 'event order is preserved');

my $array = $log->as_array;
is_deeply(
    $array->[1],
    {
        schema_version => 1,
        type           => 'strategy_result',
        sequence       => 2,
        data           => {
            strategy => 'Hidden Singles',
            count    => 1,
        },
    },
    'event log exports stable hashes',
);

is($log->clear, $log, 'clear returns the event log');
is($log->count, 0, 'clear empties the log');

my $bad = eval { Sudoku::Render::Event->new(type => 'unknown'); 1 };
ok(!$bad, 'unknown event types are rejected');
like($@, qr/Unknown event type/, 'unknown event error is useful');

done_testing();
