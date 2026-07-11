#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Deduction;
use Sudoku::Statistics;

my @deductions = (
    Sudoku::Deduction->new(
        strategy => 'Naked Singles',
        action   => 'set_value',
        row      => 0,
        column   => 0,
        value    => 1,
    ),
    Sudoku::Deduction->new(
        strategy => 'Hidden Singles',
        action   => 'set_value',
        row      => 0,
        column   => 1,
        value    => 2,
    ),
    Sudoku::Deduction->new(
        strategy => 'Naked Pairs',
        action   => 'remove_candidate',
        row      => 0,
        column   => 2,
        value    => 3,
    ),
    Sudoku::Deduction->new(
        strategy => 'Naked Pairs',
        action   => 'remove_candidate',
        row      => 0,
        column   => 3,
        value    => 3,
    ),
);

my $stats = Sudoku::Statistics->from_deductions(@deductions);

isa_ok($stats, 'Sudoku::Statistics');
is($stats->total_deductions, 4, 'total deductions are counted');
is($stats->value_placements, 2, 'set_value deductions are counted');
is($stats->candidate_removals, 2, 'remove_candidate deductions are counted');


my $contributions = $stats->contribution_by_strategy;
is_deeply(
    $contributions->{'Naked Pairs'},
    {
        deductions            => 2,
        cells_solved          => 0,
        candidates_eliminated => 2,
    },
    'contribution_by_strategy separates deductions by action',
);

is_deeply(
    $stats->strategy_contribution('Hidden Singles'),
    {
        deductions            => 1,
        cells_solved          => 1,
        candidates_eliminated => 0,
    },
    'strategy_contribution reports value placements',
);

is_deeply(
    $stats->strategy_contribution('Hidden Quads'),
    {
        deductions            => 0,
        cells_solved          => 0,
        candidates_eliminated => 0,
    },
    'strategy_contribution returns zero counts for an unused strategy',
);

is_deeply(
    $stats->count_by_action,
    {
        set_value        => 2,
        remove_candidate => 2,
    },
    'deductions are counted by action',
);

is_deeply(
    $stats->count_by_strategy,
    {
        'Naked Singles'  => 1,
        'Hidden Singles' => 1,
        'Naked Pairs'    => 2,
    },
    'deductions are counted by strategy',
);

is($stats->strategy_count('Naked Pairs'), 2, 'strategy_count returns known count');
is($stats->strategy_count('X-Wing'), 0, 'strategy_count returns zero for unused strategy');
is($stats->action_count('set_value'), 2, 'action_count returns known count');
is($stats->action_count('mark_chain'), 0, 'action_count returns zero for unused action');

is_deeply(
    [ $stats->strategies_used ],
    [ 'Hidden Singles', 'Naked Pairs', 'Naked Singles' ],
    'strategies_used returns sorted strategy names',
);

is_deeply(
    [ $stats->actions_used ],
    [ 'remove_candidate', 'set_value' ],
    'actions_used returns sorted action names',
);

my $hash = $stats->as_hash;
is($hash->{total_deductions}, 4, 'as_hash includes total deductions');
is($hash->{value_placements}, 2, 'as_hash includes value placement count');
is($hash->{candidate_removals}, 2, 'as_hash includes candidate removal count');
is($hash->{by_strategy}{'Naked Pairs'}, 2, 'as_hash includes strategy counts');
is($hash->{by_action}{remove_candidate}, 2, 'as_hash includes action counts');
is($hash->{by_strategy_action}{'Naked Pairs'}{candidates_eliminated}, 2,
    'as_hash includes per-strategy action contributions');

my $solver = Solver->new;
$solver->record_deduction($_) for @deductions[0, 2];

my $solver_stats = Sudoku::Statistics->from_solver($solver);
is($solver_stats->total_deductions, 2, 'statistics can be built from a solver');
is($solver_stats->value_placements, 1, 'solver statistics count value placements');
is($solver_stats->candidate_removals, 1, 'solver statistics count candidate removals');

my $via_solver = $solver->statistics;
isa_ok($via_solver, 'Sudoku::Statistics');
is($via_solver->total_deductions, 2, 'Solver->statistics returns current deduction statistics');

my $empty = Sudoku::Statistics->new;
is($empty->total_deductions, 0, 'empty statistics object has no deductions');
is_deeply($empty->count_by_strategy, {}, 'empty statistics has no strategy counts');
is_deeply($empty->count_by_action, {}, 'empty statistics has no action counts');

my $bad_solver = eval { Sudoku::Statistics->from_solver('not a solver'); 1 };
ok(!$bad_solver, 'from_solver rejects non-object input');
like($@, qr/deductions/, 'from_solver reports missing deductions method');

done_testing();
