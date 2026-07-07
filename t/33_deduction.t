#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Sudoku::Deduction;
use Cell;

my $deduction = Sudoku::Deduction->new(
    strategy    => 'Hidden Single',
    action      => 'set_value',
    row         => 2,
    column      => 6,
    box         => 2,
    value       => 5,
    reason      => 'Candidate 5 appears only once in row 3.',
    explanation => 'R3C7 must be 5 because no other cell in row 3 can contain 5.',
);

isa_ok($deduction, 'Sudoku::Deduction');

is($deduction->strategy, 'Hidden Single', 'strategy is stored');
is($deduction->action, 'set_value', 'action is stored');
is($deduction->row, 2, 'row is stored as zero-based index');
is($deduction->column, 6, 'column is stored as zero-based index');
is($deduction->box, 2, 'box is stored as zero-based index');
is($deduction->value, 5, 'value is stored');
ok($deduction->has_value, 'value predicate is true');
ok(!$deduction->has_candidate, 'candidate predicate is false when absent');
ok($deduction->has_cell_location, 'deduction has a cell location');
is($deduction->location, 'R3C7', 'location renders as one-based row/column');

like(
    $deduction->summary,
    qr/Hidden Single set_value R3C7 value=5/,
    'summary includes strategy, action, location, and value',
);

my $hash = $deduction->as_hash;
is($hash->{strategy}, 'Hidden Single', 'as_hash includes strategy');
is($hash->{action}, 'set_value', 'as_hash includes action');
is($hash->{row}, 2, 'as_hash includes row when present');
is($hash->{column}, 6, 'as_hash includes column when present');
is($hash->{value}, 5, 'as_hash includes value when present');
ok(!exists $hash->{candidate}, 'as_hash omits candidate when absent');

my $elimination = Sudoku::Deduction->new(
    strategy  => 'Naked Pair',
    action    => 'remove_candidate',
    row       => 4,
    column    => 1,
    candidate => 8,
);

ok($elimination->has_candidate, 'candidate predicate is true');
ok(!$elimination->has_value, 'value predicate is false when absent');
is($elimination->location, 'R5C2', 'location works for elimination deductions');
like(
    $elimination->summary,
    qr/Naked Pair remove_candidate R5C2 candidate=8/,
    'summary includes candidate when no value is present',
);

my $missing_required = eval { Sudoku::Deduction->new(action => 'set_value'); 1 };
ok(!$missing_required, 'strategy is required');

my $minimal = Sudoku::Deduction->new(
    strategy => 'Strategy Name',
    action   => 'progress',
);

is($minimal->location, q{}, 'location is empty without row and column');
ok(!$minimal->has_cell_location, 'minimal deduction has no cell location');
is_deeply($minimal->cells, [], 'cells defaults to an empty array reference');

# Ensure each instance receives its own default cells array reference.
my $another = Sudoku::Deduction->new(
    strategy => 'Another Strategy',
    action   => 'progress',
);
isnt($minimal->cells, $another->cells, 'cells default is not shared between objects');


my $cell = Cell->new;
$cell->clue(0);
$cell->row(1);
$cell->column(2);
$cell->box(0);

my $cell_deduction = Sudoku::Deduction->new(
    strategy    => 'Naked Singles',
    action      => 'set_value',
    cell        => $cell,
    value       => 9,
    explanation => 'The cell has only one candidate remaining.',
);

ok($cell_deduction->has_cell, 'cell predicate is true when a cell is supplied');
is($cell_deduction->cell, $cell, 'cell object is stored');
ok($cell_deduction->has_cell_location, 'cell-backed deduction has a location');
is($cell_deduction->location, 'R2C3', 'location renders from the cell object');
like(
    $cell_deduction->summary,
    qr/Naked Singles set_value R2C3 value=9/,
    'summary uses the cell-backed location',
);

my $cell_hash = $cell_deduction->as_hash;
is($cell_hash->{cell}, $cell, 'as_hash includes cell when present');

done_testing();
