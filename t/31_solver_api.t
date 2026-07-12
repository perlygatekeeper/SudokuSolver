#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;

my $solver = Solver->new;

isa_ok($solver, 'Solver');

can_ok(
    $solver,
    qw(
        default_puzzle_file
        strategy_classes
        strategies
        strategy_names
        debug
        trace_grid_after_deduction
        output_mode
        renderer
        emit_deduction
        deductions
        record_deduction
        clear_deductions
        deduction_count
        statistics
        explain_deduction
        explain_next
        trace_deduction
        apply_deductions
        apply_deduction
        hint
        run_strategy
        normalize_puzzle_string
        normalize_puzzle_row
        puzzle_strings_from_file
        puzzle_string_from_options
        run
    ),
);


is_deeply(
    [ $solver->strategy_names ],
    [
        'Naked Singles',
        'Hidden Singles',
        'Pointing / Claiming',
        'Naked Pairs',
        'Hidden Pairs',
        'Naked Triples',
        'Hidden Triples',
        'Naked Quads',
        'Hidden Quads',
        'X-Wing',
        'Swordfish',
        'Skyscraper',
        'Two-String Kite',
        'Empty Rectangle',
        'Simple Coloring',
        'X-Chains',
        'Multi-Coloring',
        'Remote Pairs',
        'XY-Wing',
        'XYZ-Wing',
        'WXYZ-Wing',
        'Unique Rectangle Type 1',
        'Unique Rectangle Type 2',
    ],
    'Solver exposes canonical strategy order',
);

is(
    $solver->default_puzzle_file,
    'Puzzles/sudoku17-first50.txt',
    'default puzzle file is the bundled sudoku17 puzzle list',
);

$solver->default_puzzle_file('Puzzles/Puzzle3.txt');

is_deeply(
    [ $solver->strategy_names ],
    [
        'Naked Singles',
        'Hidden Singles',
        'Pointing / Claiming',
        'Naked Pairs',
        'Hidden Pairs',
        'Naked Triples',
        'Hidden Triples',
        'Naked Quads',
        'Hidden Quads',
        'X-Wing',
        'Swordfish',
        'Skyscraper',
        'Two-String Kite',
        'Empty Rectangle',
        'Simple Coloring',
        'X-Chains',
        'Multi-Coloring',
        'Remote Pairs',
        'XY-Wing',
        'XYZ-Wing',
        'WXYZ-Wing',
        'Unique Rectangle Type 1',
        'Unique Rectangle Type 2',
    ],
    'Solver exposes canonical strategy order',
);

is(
    $solver->default_puzzle_file,
    'Puzzles/Puzzle3.txt',
    'default puzzle file can be changed',
);

my $another_solver = Solver->new(
    default_puzzle_file => 'Puzzles/Puzzle2.txt',
);

is(
    $another_solver->default_puzzle_file,
    'Puzzles/Puzzle2.txt',
    'default puzzle file can be supplied to the constructor',
);

ok(
    ! $solver->can('cells'),
    'Solver does not expose Grid internals directly',
);

ok(
    ! $solver->can('rows'),
    'Solver does not expose row internals directly',
);

done_testing();
