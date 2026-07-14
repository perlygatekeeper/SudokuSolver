#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::RemotePairs;

sub set_possibilities {
    my ($cell, @values) = @_;

    my %keep = map { $_ => 1 } @values;

    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

sub deduction_for {
    my ($deductions, $cell, $value) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $value
    } @{$deductions};
}

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# A valid four-cell Remote Pairs chain:
#
#     R1C1 -- R1C5 -- R4C5 -- R4C9
#
# Every chain cell contains {2,5}.  The endpoints R1C1 and R4C9
# have opposite values.  R1C9 sees both endpoints, so it can contain
# neither 2 nor 5.
my @chain = (
    set_possibilities($grid->cell_from_row_column(0, 0), 2, 5),
    set_possibilities($grid->cell_from_row_column(0, 4), 2, 5),
    set_possibilities($grid->cell_from_row_column(3, 4), 2, 5),
    set_possibilities($grid->cell_from_row_column(3, 8), 2, 5),
);

my $target = $grid->cell_from_row_column(0, 8);
my $other_target = $grid->cell_from_row_column(3, 0);

for my $cell ($target, $other_target) {
    ok($cell->possibilities->[2], 'candidate 2 begins possible in target');
    ok($cell->possibilities->[5], 'candidate 5 begins possible in target');
}

my @deductions = Sudoku::Strategy::RemotePairs->new->apply($grid);

is(
    deduction_for(\@deductions, $target, 2),
    1,
    'Remote Pairs removes candidate 2 from a cell that sees both endpoints',
);

is(
    deduction_for(\@deductions, $target, 5),
    1,
    'Remote Pairs removes candidate 5 from a cell that sees both endpoints',
);

my ($deduction) = grep {
       $_->cell == $target
    && $_->value == 2
} @deductions;

isa_ok($deduction, 'Sudoku::Deduction');

is_deeply(
    $deduction->cells,
    \@chain,
    'deduction records the complete alternating chain',
);

like(
    $deduction->reason,
    qr/alternating \{2,5\} chain/,
    'deduction explains the candidate pair that forms the chain',
);

like(
    $deduction->reason,
    qr/R1C9 sees opposite endpoints R1C1 and R4C9/,
    'deduction explains why the target cell is affected',
);

is(
    scalar @deductions,
    4,
    'the two cells that see both endpoints each lose both pair candidates',
);

my $progress = $grid->apply_deductions(@deductions);

is($progress, 4, 'applying the deductions removes both candidates from both targets');

for my $cell ($target, $other_target) {
    ok(!$cell->possibilities->[2], 'candidate 2 is removed from target');
    ok(!$cell->possibilities->[5], 'candidate 5 is removed from target');
}

for my $cell (@chain) {
    ok($cell->possibilities->[2], 'candidate 2 remains in chain cell');
    ok($cell->possibilities->[5], 'candidate 5 remains in chain cell');
}

# The old implementation treated any two non-seeing cells with the same pair
# as Remote Pairs and removed candidates from the rectangle intersections.
# Without a connecting chain, that deduction is invalid.
my $invalid_grid = Grid->new;
$invalid_grid->load_from_string('.' x 81);

set_possibilities(
    $invalid_grid->cell_from_row_column(0, 0),
    2,
    5,
);
set_possibilities(
    $invalid_grid->cell_from_row_column(3, 4),
    2,
    5,
);

my @invalid_deductions = Sudoku::Strategy::RemotePairs->new->apply($invalid_grid);

is(
    scalar @invalid_deductions,
    0,
    'two disconnected bivalue cells do not form a Remote Pairs chain',
);

done_testing();
