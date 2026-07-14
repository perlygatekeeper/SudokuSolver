#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::AIC;

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
    return scalar grep { $_->cell == $cell && $_->value == $value } @{$deductions};
}

my $strategy = Sudoku::Strategy::AIC->new;
is($strategy->name, 'AIC', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Candidate-node AIC:
# R1C1(1) =S= R1C1(2) -W- R1C4(2)
#          =S= R1C4(3) -W- R4C4(3)
#          =S= R4C4(1)
# R4C1 sees both candidate-1 endpoints and loses candidate 1.
my $first  = set_possibilities($grid->cell_from_row_column(0, 0), 1, 2);
my $second = set_possibilities($grid->cell_from_row_column(0, 3), 2, 3);
my $last   = set_possibilities($grid->cell_from_row_column(3, 3), 1, 3);
my $target = $grid->cell_from_row_column(3, 0);

my @deductions = $strategy->apply($grid);
is(deduction_for(\@deductions, $target, 1), 1,
    'AIC removes a candidate seen by both same-candidate endpoints');

my ($deduction) = grep { $_->cell == $target && $_->value == 1 } @deductions;
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'AIC', 'deduction records strategy');
is($deduction->action, 'remove_candidate', 'deduction removes a candidate');
like($deduction->reason, qr/alternating inference chain/i,
    'reason identifies the AIC');
like($deduction->reason, qr/=S=.*-W-.*=S=/,
    'reason displays alternating strong and weak links');
like($deduction->explanation, qr/cannot both be false/,
    'explanation states the endpoint inference');

is($grid->apply_deductions($deduction), 1, 'AIC deduction applies');
ok(!$target->possibilities->[1], 'target loses candidate 1');

my $broken = Grid->new;
$broken->load_from_string('.' x 81);
set_possibilities($broken->cell_from_row_column(0, 0), 1, 2);
set_possibilities($broken->cell_from_row_column(0, 3), 4, 5);
set_possibilities($broken->cell_from_row_column(3, 3), 1, 3);

is(scalar $strategy->apply($broken), 0,
    'broken alternating links do not form an AIC');

done_testing();
