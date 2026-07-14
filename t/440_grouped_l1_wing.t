#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::InferenceNode;
use Sudoku::StrongLinks qw(
    grouped_strong_links_for_digit
    nodes_are_weakly_linked
    cell_sees_node
);
use Sudoku::Strategy::GroupedL1Wing;

sub retain_candidate_only_at {
    my ( $grid, $digit, @keep ) = @_;
    my %keep = map { $_ => 1 } @keep;

    for my $cell ( @{ $grid->cells } ) {
        next if $keep{$cell};
        $cell->remove_possibility($digit);
    }
}

sub deduction_for {
    my ( $deductions, $cell, $value ) = @_;
    return scalar grep {
        $_->cell == $cell && $_->value == $value
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::GroupedL1Wing->new;
is($strategy->name, 'Grouped L1-Wing', 'strategy reports canonical name');

my $grid = Grid->new;
$grid->load_from_string('.' x 81);

# Candidate 7 forms:
#
# R2C3(7) =S= {R1C1,R1C2}(7)
#             -W- R1C5(7)
#                  =S= {R2C4,R2C6}(7)
#
# R2C9 sees the singleton left endpoint and every cell in the grouped right
# endpoint, so candidate 7 can be removed from R2C9.
my $left       = $grid->cell_from_row_column(1, 2); # R2C3
my $group_b_1  = $grid->cell_from_row_column(0, 0); # R1C1
my $group_b_2  = $grid->cell_from_row_column(0, 1); # R1C2
my $inner      = $grid->cell_from_row_column(0, 4); # R1C5
my $group_d_1  = $grid->cell_from_row_column(1, 3); # R2C4
my $group_d_2  = $grid->cell_from_row_column(1, 5); # R2C6
my $target     = $grid->cell_from_row_column(1, 8); # R2C9

retain_candidate_only_at(
    $grid, 7,
    $left, $group_b_1, $group_b_2, $inner,
    $group_d_1, $group_d_2, $target,
);

my @links = grouped_strong_links_for_digit($grid, 7);
ok(@links >= 2, 'grouped strong-link discovery finds both box links');
my $grouped_link_count = grep {
    $_->{nodes}[0]->is_group || $_->{nodes}[1]->is_group
} @links;
ok(
    $grouped_link_count,
    'at least one discovered strong link contains a grouped node',
);

my $group_node = Sudoku::InferenceNode->new(
    digit => 7,
    cells => [ $group_b_1, $group_b_2 ],
);
my $inner_node = Sudoku::InferenceNode->new(
    digit => 7,
    cells => [ $inner ],
);
ok(nodes_are_weakly_linked($group_node, $inner_node),
    'all cells in a grouped node can share a weak link with a singleton');
ok(cell_sees_node($target, Sudoku::InferenceNode->new(
        digit => 7,
        cells => [ $group_d_1, $group_d_2 ],
    )),
    'target sees every possible location in a grouped endpoint');

my @deductions = $strategy->apply($grid);
is(deduction_for(\@deductions, $target, 7), 1,
    'Grouped L1-Wing removes the candidate seen by both endpoints');

my ($deduction) = grep {
    $_->cell == $target && $_->value == 7
} @deductions;
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->strategy, 'Grouped L1-Wing', 'deduction records strategy');
like($deduction->reason, qr/\{R1C1,R1C2\}\(7\)/,
    'reason displays a grouped candidate node');
like($deduction->reason, qr/=S=.*-W-.*=S=/,
    'reason displays the strong-weak-strong chain');

my $partial = $grid->cell_from_row_column(3, 3); # sees R2C4, not R2C6
ok(!cell_sees_node($partial, Sudoku::InferenceNode->new(
        digit => 7,
        cells => [ $group_d_1, $group_d_2 ],
    )),
    'seeing only part of a group is insufficient for an elimination');

my $broken = Grid->new;
$broken->load_from_string('.' x 81);
my @broken_keep = map {
    $broken->cell_from_row_column(@{$_})
} ([1,2], [0,0], [0,1], [3,4], [1,3], [1,5], [1,8]);
retain_candidate_only_at($broken, 7, @broken_keep);
is(scalar $strategy->apply($broken), 0,
    'groups without an all-to-all weak connection do not form a wing');

done_testing();
