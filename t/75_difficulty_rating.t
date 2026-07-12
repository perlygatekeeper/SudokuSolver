#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Deduction;
use Sudoku::Difficulty;
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
        strategy => 'Pointing / Claiming',
        action   => 'remove_candidate',
        row      => 0,
        column   => 1,
        value    => 2,
    ),
    Sudoku::Deduction->new(
        strategy => 'X-Wing',
        action   => 'remove_candidate',
        row      => 0,
        column   => 2,
        value    => 3,
    ),
);

my $stats = Sudoku::Statistics->from_deductions(@deductions);
is($stats->highest_strategy, 'X-Wing', 'statistics identify highest strategy used');
is($stats->strategy_rank('X-Wing'), 7, 'statistics expose strategy rank');
is($stats->strategy_rank('Unknown'), 0, 'unknown strategies have rank zero');

my $difficulty = Sudoku::Difficulty->from_statistics($stats);
isa_ok($difficulty, 'Sudoku::Difficulty');
is($difficulty->rating_version, '2.2', 'difficulty rating records method version');
is($difficulty->label, 'Expert', 'difficulty label comes from highest strategy');
is($difficulty->score, 5, 'difficulty score comes from highest strategy');
is($difficulty->highest_strategy, 'X-Wing', 'difficulty records highest strategy');
is($difficulty->statistics_snapshot->{total_deductions}, 3, 'difficulty keeps statistics snapshot');
is($difficulty->statistics_snapshot->{highest_strategy}, 'X-Wing', 'snapshot records highest strategy');
like($difficulty->summary, qr/Expert/, 'summary includes label');
like($difficulty->summary, qr/v2\.2/, 'summary includes rating version');
like($difficulty->summary, qr/X-Wing/, 'summary includes highest strategy');

my $hash = $difficulty->as_hash;
is($hash->{rating_version}, '2.2', 'as_hash includes rating version');
is($hash->{label}, 'Expert', 'as_hash includes label');
is($hash->{score}, 5, 'as_hash includes score');
is($hash->{highest_strategy}, 'X-Wing', 'as_hash includes highest strategy');
is($hash->{statistics_snapshot}{by_strategy}{'X-Wing'}, 1, 'as_hash includes statistics snapshot');


is(Sudoku::Difficulty->new(label => 'x', score => 0, statistics_snapshot => {})->strategy_score('XY-Wing'), 6, 'XY-Wing has an active difficulty score');
is(Sudoku::Difficulty->new(label => 'x', score => 0, statistics_snapshot => {})->strategy_score('XYZ-Wing'), 7, 'XYZ-Wing has an active difficulty score');
is(Sudoku::Difficulty->new(label => 'x', score => 0, statistics_snapshot => {})->strategy_score('WXYZ-Wing'), 8, 'WXYZ-Wing has an active difficulty score');

my $empty_stats = Sudoku::Statistics->new;
my $empty_difficulty = Sudoku::Difficulty->from_statistics($empty_stats);
is($empty_difficulty->label, 'Unrated', 'empty statistics are unrated');
is($empty_difficulty->score, 0, 'empty statistics have score zero');
ok(!$empty_difficulty->has_highest_strategy, 'empty difficulty has no highest strategy');

my $solver = Solver->new;
$solver->record_deduction($_) for @deductions;
my $solver_difficulty = $solver->difficulty;
isa_ok($solver_difficulty, 'Sudoku::Difficulty');
is($solver_difficulty->label, 'Expert', 'Solver->difficulty rates current deductions');
is($solver_difficulty->statistics_snapshot->{total_deductions}, 3, 'Solver->difficulty snapshots solver statistics');

my $bad_stats = eval { Sudoku::Difficulty->from_statistics('not statistics'); 1 };
ok(!$bad_stats, 'from_statistics rejects non-statistics input');
like($@, qr/Sudoku::Statistics/, 'from_statistics reports required type');

my $bad_solver = eval { Sudoku::Difficulty->from_solver('not solver'); 1 };
ok(!$bad_solver, 'from_solver rejects non-solver input');
like($@, qr/statistics/, 'from_solver reports missing statistics method');


is(
    $difficulty->strategy_score('Unique Rectangle Type 1'),
    6,
    'Unique Rectangle Type 1 has a provisional difficulty score',
);

is(
    $difficulty->strategy_score('Unique Rectangle Type 2'),
    6,
    'Unique Rectangle Type 2 has a provisional difficulty score',
);



is(
    $difficulty->strategy_score('Unique Rectangle Type 3'),
    7,
    'Unique Rectangle Type 3 has an active difficulty score',
);

is(
    $difficulty->strategy_score('Unique Rectangle Type 4'),
    7,
    'Unique Rectangle Type 4 has an active difficulty score',
);

is(
    $difficulty->strategy_score('Skyscraper'),
    7,
    'Skyscraper has an active difficulty score',
);

is(
    $difficulty->strategy_score('Two-String Kite'),
    7,
    'Two-String Kite has an active difficulty score',
);

is(
    $difficulty->strategy_score('Empty Rectangle'),
    7,
    'Empty Rectangle has an active difficulty score',
);


is(
    $difficulty->strategy_score('Simple Coloring'),
    8,
    'Simple Coloring has an active difficulty score',
);


is(
    $difficulty->strategy_score('X-Chains'),
    9,
    'X-Chains has an active difficulty score',
);


is(
    $difficulty->strategy_score('XY-Chains'),
    9,
    'XY-Chains has an active difficulty score',
);

is(
    $difficulty->strategy_score('Multi-Coloring'),
    9,
    'Multi-Coloring has an active difficulty score',
);

is(
    $difficulty->strategy_score('Swordfish'),
    7,
    'Swordfish has an active difficulty score',
);

done_testing();
