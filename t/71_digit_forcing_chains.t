#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Hypothetical::Result;
use Sudoku::Strategy::DigitForcingChains;

sub set_candidates {
    my ($cell, @values) = @_;

    my @possibilities = (0) x 10;
    $possibilities[$_] = $_ for @values;
    $possibilities[0] = scalar @values;
    $cell->value(0);
    $cell->possibilities(\@possibilities);

    return $cell;
}

sub isolated_grid {
    my $grid = Grid->new;
    $grid->load_from_string('9' x 81);
    return $grid;
}

my $strategy = Sudoku::Strategy::DigitForcingChains->new(
    strategy_classes => ['Sudoku::Strategy::NakedSingles'],
    max_branch_steps => 20,
);

is($strategy->name, 'Digit Forcing Chains', 'strategy reports canonical name');

{
    package Local::DigitForcingChains;
    use parent 'Sudoku::Strategy::DigitForcingChains';

    sub _run_branch {
        my ( $self, $grid, $cell, $value, $assumption ) = @_;
        return $self->{$assumption};
    }
}


{
    package Local::PremiseDigitForcingChains;
    use parent 'Sudoku::Strategy::DigitForcingChains';

    sub _run_branch {
        my ( $self, $grid, $cell, $value, $assumption ) = @_;
        push @{ $self->{calls} }, [ $cell->row, $cell->column, $value, $assumption ];

        if ($value == 3 && $assumption eq 'on') {
            return $self->{contradiction_result};
        }

        return $self->{fixed_result};
    }
}

sub result_with_grid {
    my ($grid, $assumption, $steps, $contradiction) = @_;
    my %args = (
        status     => $contradiction ? 'contradiction' : 'fixed_point',
        assumption => {
            row => 0, column => 0, value => 1, state => $assumption,
        },
        grid  => $grid,
        steps => $steps,
    );
    $args{contradiction} = $contradiction if $contradiction;

    return Sudoku::Hypothetical::Result->new(%args);
}

# Test contradiction comparison with explicit branch results. Hypothetical
# propagation itself is covered independently by t/70_hypothetical.t.
my $grid = isolated_grid();
set_candidates($grid->cell_from_row_column(0, 0), 1, 2);

my $contradiction_on_grid = isolated_grid();
set_candidates($contradiction_on_grid->cell_from_row_column(0, 0), 1);

my $contradiction_off_grid = isolated_grid();
set_candidates($contradiction_off_grid->cell_from_row_column(0, 0), 2);

require Sudoku::Contradiction;
my $on_contradiction = Sudoku::Contradiction->new(
    kind        => 'zero_candidates',
    message     => 'Synthetic ON-branch contradiction.',
    cell        => $contradiction_on_grid->cell_from_row_column(0, 1),
    explanation => 'Synthetic ON-branch contradiction.',
);

my $contradiction_strategy = Local::DigitForcingChains->new(
    on  => result_with_grid($contradiction_on_grid,  'on',  1, $on_contradiction),
    off => result_with_grid($contradiction_off_grid, 'off', 2),
);

my @deductions = $contradiction_strategy->apply($grid);
is(scalar @deductions, 1, 'contradictory ON branch produces one deduction');
my $deduction = $deductions[0];
isa_ok($deduction, 'Sudoku::Deduction');
is($deduction->action, 'remove_candidate', 'contradictory ON branch removes the premise');
is($deduction->value, 1, 'correct premise candidate is removed');
is($deduction->cell, $grid->cell_from_row_column(0, 0), 'deduction targets source grid cell');
like($deduction->reason, qr/contradiction/, 'reason identifies contradiction proof');
is($grid->cell_from_row_column(0, 0)->value, 0, 'strategy discovery does not mutate source value');
ok($grid->cell_from_row_column(0, 0)->possibilities->[1],
    'strategy discovery does not remove source candidate');

my $common_source = isolated_grid();
set_candidates($common_source->cell_from_row_column(0, 0), 1, 2);
set_candidates($common_source->cell_from_row_column(4, 4), 3, 4);

my $on_grid = isolated_grid();
set_candidates($on_grid->cell_from_row_column(0, 0), 1);
set_candidates($on_grid->cell_from_row_column(4, 4), 4);

my $off_grid = isolated_grid();
set_candidates($off_grid->cell_from_row_column(0, 0), 2);
set_candidates($off_grid->cell_from_row_column(4, 4), 4);

my $common_strategy = Local::DigitForcingChains->new(
    on  => result_with_grid($on_grid,  'on',  3),
    off => result_with_grid($off_grid, 'off', 4),
);

my @common = $common_strategy->apply($common_source);
is(scalar @common, 1, 'common branch conclusion produces one deduction');
is($common[0]->action, 'remove_candidate', 'common false candidate is removed');
is($common[0]->value, 3, 'correct common candidate is removed');
is($common[0]->cell, $common_source->cell_from_row_column(4, 4),
    'common conclusion targets source grid cell');
like($common[0]->reason, qr/Whether .* is 1 or is not 1/,
    'reason describes both branches');

my $placement_source = isolated_grid();
set_candidates($placement_source->cell_from_row_column(0, 0), 1, 2);
set_candidates($placement_source->cell_from_row_column(3, 3), 5, 6);

my $placement_on = isolated_grid();
set_candidates($placement_on->cell_from_row_column(0, 0), 1);
$placement_on->cell_from_row_column(3, 3)->value(5);
$placement_on->cell_from_row_column(3, 3)->possibilities([(0) x 10]);

my $placement_off = isolated_grid();
set_candidates($placement_off->cell_from_row_column(0, 0), 2);
$placement_off->cell_from_row_column(3, 3)->value(5);
$placement_off->cell_from_row_column(3, 3)->possibilities([(0) x 10]);

my $placement_strategy = Local::DigitForcingChains->new(
    on  => result_with_grid($placement_on,  'on',  2),
    off => result_with_grid($placement_off, 'off', 2),
);
my @placements = $placement_strategy->apply($placement_source);
is($placements[0]->action, 'set_value', 'common placement is preferred');
is($placements[0]->value, 5, 'common placement uses agreed value');
is($placements[0]->cell, $placement_source->cell_from_row_column(3, 3),
    'common placement targets source cell');


# Non-bivalue premises are eligible, and a contradictory ON branch returns
# immediately without paying for the OFF branch.
my $broad_grid = Grid->new;
$broad_grid->load_from_string(('0' x 80) . '9');
set_candidates($broad_grid->cell_from_row_column(0, 0), 1, 2, 3);

my $broad_fixed_grid = Grid->new;
$broad_fixed_grid->load_from_string(('0' x 80) . '9');
set_candidates($broad_fixed_grid->cell_from_row_column(0, 0), 1, 2, 3);

my $broad_bad_grid = Grid->new;
$broad_bad_grid->load_from_string(('0' x 80) . '9');
set_candidates($broad_bad_grid->cell_from_row_column(0, 0), 1, 2, 3);

my $broad_contradiction = Sudoku::Contradiction->new(
    kind        => 'zero_candidates',
    message     => 'Synthetic non-bivalue ON contradiction.',
    cell        => $broad_bad_grid->cell_from_row_column(0, 1),
    explanation => 'Synthetic non-bivalue ON contradiction.',
);

my $premise_strategy = Local::PremiseDigitForcingChains->new(
    calls => [],
    fixed_result => result_with_grid($broad_fixed_grid, 'on', 2),
    contradiction_result => result_with_grid(
        $broad_bad_grid, 'on', 3, $broad_contradiction,
    ),
);

my @broad_deductions = $premise_strategy->apply($broad_grid);
is(scalar @broad_deductions, 1,
    'candidate in a three-candidate cell can be used as a forcing premise');
is($broad_deductions[0]->action, 'remove_candidate',
    'contradictory non-bivalue premise removes the candidate');
is($broad_deductions[0]->value, 3,
    'non-bivalue contradiction removes the tested candidate');
my $candidate_three_off_calls = grep {
    $_->[0] == 0 && $_->[1] == 0 && $_->[2] == 3 && $_->[3] eq 'off'
} @{ $premise_strategy->{calls} };
is($candidate_three_off_calls, 0,
    'OFF branch is skipped after an ON contradiction');

my $empty_grid = Grid->new;
$empty_grid->load_from_string('0' x 81);
my @empty_deductions = $premise_strategy->apply($empty_grid);
is(scalar @empty_deductions, 0,
    'completely empty grid is rejected as an underconstrained forcing state');

done_testing();
