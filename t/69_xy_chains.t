#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::XYChains;

sub set_possibilities {
    my ( $cell, @values ) = @_;

    my %keep = map { $_ => 1 } @values;
    for my $value (1 .. 9) {
        next if $keep{$value};
        $cell->remove_possibility($value);
    }

    return $cell;
}

sub deduction_for {
    my ( $deductions, $cell, $value ) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $value
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::XYChains->new;
is($strategy->name, 'XY-Chains', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# R1C1 {1,9} - R1C4 {1,2} - R4C4 {2,3} - R4C7 {3,9}
# R1C7 sees both endpoints, so it cannot contain 9.
my $first  = set_possibilities($grid->cell_from_row_column(0, 0), 1, 9);
my $second = set_possibilities($grid->cell_from_row_column(0, 3), 1, 2);
my $third  = set_possibilities($grid->cell_from_row_column(3, 3), 2, 3);
my $last   = set_possibilities($grid->cell_from_row_column(3, 6), 3, 9);
my $target = $grid->cell_from_row_column(0, 6);

my @deductions = $strategy->apply($grid);

is(deduction_for(\@deductions, $target, 9), 1,
    'XY-Chain removes the endpoint candidate from a common peer');

my ($deduction) = grep { $_->cell == $target && $_->value == 9 } @deductions;
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'XY-Chains', 'deduction records strategy');
is($deduction->action, 'remove_candidate', 'deduction removes a candidate');
is_deeply($deduction->cells, [ $first, $second, $third, $last ],
    'deduction records the ordered chain cells');
like($deduction->reason, qr/bivalue cells form the XY-Chain/,
    'reason identifies the XY-Chain');
like($deduction->reason, qr/R1C1\{1,9\}.*R4C7\{3,9\}/,
    'reason displays endpoint candidates');
like($deduction->explanation, qr/cannot both exclude 9/,
    'explanation states the endpoint inference');

is($grid->apply_deductions($deduction), 1, 'XY-Chain deduction applies');
ok(!$target->possibilities->[9], 'target loses candidate 9');

my $broken = Grid->new;
$broken->load_from_string('.' x 81);
set_possibilities($broken->cell_from_row_column(0, 0), 1, 9);
set_possibilities($broken->cell_from_row_column(0, 3), 1, 2);
set_possibilities($broken->cell_from_row_column(3, 3), 4, 5);
set_possibilities($broken->cell_from_row_column(3, 6), 3, 9);

is(scalar $strategy->apply($broken), 0,
    'broken candidate sequence does not form an XY-Chain');

my $no_target = Grid->new;
$no_target->load_from_string('.' x 81);
set_possibilities($no_target->cell_from_row_column(0, 0), 1, 9);
set_possibilities($no_target->cell_from_row_column(0, 3), 1, 2);
set_possibilities($no_target->cell_from_row_column(3, 3), 2, 3);
set_possibilities($no_target->cell_from_row_column(3, 6), 3, 9);
for my $cell (@{ $no_target->cells }) {
    next if $cell->possibilities->[0] == 2;
    $cell->remove_possibility(9);
}

is(scalar $strategy->apply($no_target), 0,
    'valid chain without a common-peer target makes no deduction');

done_testing();
