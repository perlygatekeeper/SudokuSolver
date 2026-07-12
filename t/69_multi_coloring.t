#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::StrongLinks qw(
    candidate_graph_for_digit
    connected_components
    color_component
);
use Sudoku::Strategy::MultiColoring;

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

my $strategy = Sudoku::Strategy::MultiColoring->new;
is($strategy->name, 'Multi-Coloring', 'strategy reports canonical name');

my $collision_grid = Grid->new;
$collision_grid->load_from_string('.' x 81);

# Component one is the column strong link R2C3--R5C3.
# Component two is the row strong link R1C1--R1C2.
# R2C3 sees both colors of component two through box 1, so its color is false.
keep_candidate_only_at(
    $collision_grid,
    4,
    [ 1, 2 ],    # R2C3 false color
    [ 4, 2 ],    # R5C3 opposite color
    [ 0, 0 ],    # R1C1 other component, color A
    [ 0, 1 ],    # R1C2 other component, color B
);

my $collision_graph = candidate_graph_for_digit($collision_grid, 4);
my @collision_components = connected_components($collision_graph);
is(scalar @collision_components, 2,
    'collision fixture contains two separate colored components');

my ($colors, $conflicted)
    = color_component($collision_graph, $collision_components[0]);
ok(!$conflicted, 'shared component coloring reports no conflict');
is(scalar keys %{$colors}, 2, 'shared coloring helper colors the component');

my $collision_target = $collision_grid->cell_from_row_column(1, 2);
my @collision_deductions = $strategy->apply($collision_grid);

is(deduction_for(\@collision_deductions, $collision_target, 4), 1,
    'color collision removes the impossible component color');
my ($collision_deduction) = grep {
    $_->cell == $collision_target && $_->value == 4
} @collision_deductions;
isa_ok($collision_deduction, 'Sudoku::Deduction');
is($collision_deduction->strategy, 'Multi-Coloring',
    'collision deduction records strategy');
like($collision_deduction->reason, qr/sees both colors of the other component/,
    'collision reason explains the cross-component contradiction');
like($collision_deduction->explanation, qr/Multi-Coloring collision/,
    'collision explanation names the rule');

my $wing_grid = Grid->new;
$wing_grid->load_from_string('.' x 81);

# Component one: R1C1--R1C5.
# Component two: R2C2--R2C6.
# R1C1 and R2C2 are same-color candidates that see each other in box 1.
# Their opposite colors R1C5 and R2C6 are therefore jointly true.
# R3C4 sees both opposites in box 2 and loses candidate 6.
# Extra row-3 candidates prevent the target and box blocker from forming a
# separate strong-link component.
keep_candidate_only_at(
    $wing_grid,
    6,
    [ 0, 0 ],    # R1C1 same-color contact
    [ 0, 4 ],    # R1C5 opposite color
    [ 1, 1 ],    # R2C2 same-color contact
    [ 1, 5 ],    # R2C6 opposite color
    [ 2, 2 ],    # box-1 blocker
    [ 2, 3 ],    # R3C4 target
    [ 2, 8 ],    # row-3 blocker
);

my $wing_graph = candidate_graph_for_digit($wing_grid, 6);
my @wing_components = connected_components($wing_graph);
is(scalar @wing_components, 2,
    'wing fixture contains two separate colored components');

my $wing_target = $wing_grid->cell_from_row_column(2, 3);
my @wing_deductions = $strategy->apply($wing_grid);

is(deduction_for(\@wing_deductions, $wing_target, 6), 1,
    'color wing removes candidate seeing both forced opposite colors');
my ($wing_deduction) = grep {
    $_->cell == $wing_target && $_->value == 6
} @wing_deductions;
isa_ok($wing_deduction, 'Sudoku::Deduction');
like($wing_deduction->reason, qr/same-color candidates from different components/,
    'wing reason identifies the cross-component color contact');
like($wing_deduction->explanation, qr/Multi-Coloring wing/,
    'wing explanation names the rule');

my $no_deduction_grid = Grid->new;
$no_deduction_grid->load_from_string('.' x 81);
keep_candidate_only_at(
    $no_deduction_grid,
    8,
    [ 0, 0 ], [ 0, 4 ],
    [ 6, 1 ], [ 6, 5 ],
);

is(scalar $strategy->apply($no_deduction_grid), 0,
    'separate components without cross-color interaction make no deduction');

done_testing();
