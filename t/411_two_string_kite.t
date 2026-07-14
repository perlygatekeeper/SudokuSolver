#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::TwoStringKite;

sub keep_candidate_only_at {
    my ( $grid, $value, @coordinates ) = @_;

    my %keep = map { ( join(q{:}, @{$_}) => 1 ) } @coordinates;

    for my $row (0 .. 8) {
        for my $column (0 .. 8) {
            next if $keep{ join(q{:}, $row, $column) };
            $grid->cell_from_row_column($row, $column)
                ->remove_possibility($value);
        }
    }
}

sub deduction_for {
    my ( $deductions, $cell, $value ) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $value
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::TwoStringKite->new;
is($strategy->name, 'Two-String Kite', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Candidate 5 has a row strong link R1C1-R1C5 and a column strong
# link R2C2-R6C2.  R1C1 and R2C2 share the top-left box, joining
# the two strings.  The remote endpoints are R1C5 and R6C2, so
# R6C5 cannot contain 5 because it sees both remote endpoints.
keep_candidate_only_at(
    $grid,
    5,
    [ 0, 0 ],    # R1C1 row connector
    [ 0, 4 ],    # R1C5 row remote endpoint
    [ 1, 1 ],    # R2C2 column connector
    [ 5, 1 ],    # R6C2 column remote endpoint
    [ 5, 4 ],    # R6C5 target
);

my $target = $grid->cell_from_row_column(5, 4);
my @deductions = $strategy->apply($grid);

is(scalar @deductions, 1, 'Two-String Kite finds one elimination');
is(deduction_for(\@deductions, $target, 5), 1,
    'Two-String Kite removes candidate from common peer');

my $deduction = $deductions[0];
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'Two-String Kite', 'deduction records strategy');
is($deduction->action, 'remove_candidate', 'deduction removes a candidate');
like($deduction->reason, qr/R1C5-R1C1 is a strong link in row 1/,
    'reason identifies row string');
like($deduction->reason, qr/R2C2-R6C2 is a strong link in column 2/,
    'reason identifies column string');
like($deduction->reason, qr/R1C1 and R2C2 share box 1/,
    'reason identifies box connection');
like($deduction->reason, qr/R6C5 cannot contain 5/,
    'reason identifies target and candidate');

is($grid->apply_deductions(@deductions), 1, 'deduction applies');
ok(!$target->possibilities->[5], 'target loses candidate');

my $disconnected_grid = Grid->new;
$disconnected_grid->load_from_string('.' x 81);

# The row and column strings exist, but no endpoint from one string
# shares a box with an endpoint from the other.
keep_candidate_only_at(
    $disconnected_grid,
    6,
    [ 0, 0 ], [ 0, 4 ],
    [ 3, 8 ], [ 7, 8 ],
    [ 7, 4 ],
);

is(scalar $strategy->apply($disconnected_grid), 0,
    'disconnected row and column strings are not a kite');

my $weak_row_grid = Grid->new;
$weak_row_grid->load_from_string('.' x 81);

# Three candidates in row 1 mean that row does not provide a strong link.
keep_candidate_only_at(
    $weak_row_grid,
    7,
    [ 0, 0 ], [ 0, 4 ], [ 0, 8 ],
    [ 1, 1 ], [ 5, 1 ],
    [ 5, 4 ],
);

is(scalar $strategy->apply($weak_row_grid), 0,
    'a row with three candidates is not a strong string');

my $shared_cell_grid = Grid->new;
$shared_cell_grid->load_from_string('.' x 81);

# The row and column strong links meet at the same cell.  That is a
# different chain shape and must not be reported as a Two-String Kite.
keep_candidate_only_at(
    $shared_cell_grid,
    8,
    [ 0, 0 ], [ 0, 4 ],
    [ 5, 0 ],
    [ 5, 4 ],
);

is(scalar $strategy->apply($shared_cell_grid), 0,
    'strong links sharing one cell are not a Two-String Kite');

done_testing();
