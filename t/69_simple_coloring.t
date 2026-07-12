#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::StrongLinks qw(
    candidate_graph_for_digit
    connected_components
    strong_links_for_digit
);
use Sudoku::Strategy::SimpleColoring;

sub keep_candidate_only_at {
    my ( $grid, $digit, @coordinates ) = @_;

    my %keep = map { ( join(q{:}, @{$_}) => 1 ) } @coordinates;

    for my $row (0 .. 8) {
        for my $column (0 .. 8) {
            next if $keep{ join(q{:}, $row, $column) };
            $grid->cell_from_row_column($row, $column)
                ->remove_possibility($digit);
        }
    }
}

sub deduction_for {
    my ( $deductions, $cell, $digit ) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $digit
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::SimpleColoring->new;
is($strategy->name, 'Simple Coloring', 'strategy reports canonical name');

my $trap_grid = Grid->new;
$trap_grid->load_from_string('.' x 81);

# Candidate 5 forms one connected strong-link chain:
#
#   R4C2 -- R8C2 -- R7C1 -- R7C4 -- R8C4
#
# Alternating colors make R8C2 and R8C4 opposite colors.  R8C7 is
# outside the chain but sees both through row 8, so it is a color trap.
keep_candidate_only_at(
    $trap_grid,
    5,
    [ 3, 1 ],    # R4C2
    [ 7, 1 ],    # R8C2
    [ 6, 0 ],    # R7C1
    [ 6, 3 ],    # R7C4
    [ 7, 3 ],    # R8C4
    [ 7, 6 ],    # R8C7 target
);

my @links = strong_links_for_digit($trap_grid, 5);
ok(@links >= 4, 'strong-link helper finds the coloring chain');

my $graph = candidate_graph_for_digit($trap_grid, 5);
my @components = connected_components($graph);
is(scalar @components, 1, 'strong-link graph has one connected component');
is(scalar @{ $components[0]{cells} }, 5,
    'unlinked trap target is not part of the colored component');

my $trap_target = $trap_grid->cell_from_row_column(7, 6);
my @trap_deductions = $strategy->apply($trap_grid);

is(scalar @trap_deductions, 1, 'color trap finds one elimination');
is(deduction_for(\@trap_deductions, $trap_target, 5), 1,
    'color trap removes candidate from cell seeing both colors');

my $trap_deduction = $trap_deductions[0];
isa_ok($trap_deduction, 'Sudoku::Deduction');
is($trap_deduction->strategy, 'Simple Coloring',
    'trap deduction records strategy');
is($trap_deduction->action, 'remove_candidate',
    'trap deduction removes a candidate');
like($trap_deduction->reason, qr/alternately to colors A and B/,
    'trap reason explains alternating colors');
like($trap_deduction->reason, qr/R8C7 sees color A .* color B/s,
    'trap reason identifies both visible colors');
like($trap_deduction->explanation, qr/Simple Coloring trap/,
    'trap explanation names the rule');

is($trap_grid->apply_deductions(@trap_deductions), 1,
    'trap deduction applies');
ok(!$trap_target->possibilities->[5],
    'trap target loses candidate');

my $wrap_grid = Grid->new;
$wrap_grid->load_from_string('.' x 81);

# R1C9--R2C9 is a column strong link and R2C9--R2C7 is a row
# strong link.  R1C9 and R2C7 receive the same color but see each
# other in box 3, so that color is false at both cells.
keep_candidate_only_at(
    $wrap_grid,
    7,
    [ 0, 8 ],    # R1C9 false color
    [ 1, 8 ],    # R2C9 opposite color
    [ 1, 6 ],    # R2C7 false color
);

my $wrap_first  = $wrap_grid->cell_from_row_column(0, 8);
my $wrap_second = $wrap_grid->cell_from_row_column(1, 6);
my @wrap_deductions = $strategy->apply($wrap_grid);

is(scalar @wrap_deductions, 2,
    'color wrap removes every candidate of the contradictory color');
is(deduction_for(\@wrap_deductions, $wrap_first, 7), 1,
    'color wrap removes candidate from first conflicting cell');
is(deduction_for(\@wrap_deductions, $wrap_second, 7), 1,
    'color wrap removes candidate from second conflicting cell');
like($wrap_deductions[0]->reason, qr/both have color [AB] and see each other/,
    'wrap reason identifies same-color contradiction');
like($wrap_deductions[0]->explanation, qr/Simple Coloring wrap/,
    'wrap explanation names the rule');

my $no_deduction_grid = Grid->new;
$no_deduction_grid->load_from_string('.' x 81);

# A valid alternating chain by itself is not enough.  With no same-color
# conflict and no external candidate seeing both colors, there is no deduction.
keep_candidate_only_at(
    $no_deduction_grid,
    8,
    [ 3, 1 ], [ 7, 1 ], [ 6, 0 ], [ 6, 3 ], [ 7, 3 ],
);

is(scalar $strategy->apply($no_deduction_grid), 0,
    'a colored component without a trap or wrap makes no deduction');

done_testing();
