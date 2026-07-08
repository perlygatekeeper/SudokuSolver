#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Deduction;

{
    package Local::Hint::SetFirst;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Hint First' }

    sub apply {
        my ( $self, $grid ) = @_;
        $calls++;

        my $cell = $grid->cell_from_row_column(0, 0);
        return if $cell->value;

        return Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'set_value',
            cell     => $cell,
            value    => 1,
            reason   => 'Local hint test deduction.',
        );
    }
}

{
    package Local::Hint::ShouldNotRun;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Hint Should Not Run' }

    sub apply {
        $calls++;
        return;
    }
}

{
    package Local::Hint::NoProgress;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Hint No Progress' }

    sub apply {
        $calls++;
        return;
    }
}

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $solver = Solver->new(
    strategy_classes => [
        'Local::Hint::SetFirst',
        'Local::Hint::ShouldNotRun',
    ],
);

my $solved_before    = $grid->solved;
my $cell_value_before = $grid->cell_from_row_column(0, 0)->value;
my $deductions_before = $solver->deduction_count;

my $hint = $solver->hint($grid);

isa_ok($hint, 'Sudoku::Deduction', 'hint returns the next deduction');
is($hint->strategy, 'Local Hint First', 'hint returns the first available strategy deduction');
is($hint->action, 'set_value', 'hint reports the deduction action');
is($hint->value, 1, 'hint reports the deduction value');
is($grid->solved, $solved_before, 'hint does not change solved cell count');
is($grid->cell_from_row_column(0, 0)->value, $cell_value_before, 'hint does not apply the deduction');
is($solver->deduction_count, $deductions_before, 'hint does not record the deduction');
is($Local::Hint::SetFirst::calls, 1, 'hint calls the first strategy');
is($Local::Hint::ShouldNotRun::calls, 0, 'hint stops after the first available deduction');

my $step = $solver->step($grid);

isa_ok($step, 'Sudoku::Deduction', 'step still returns a deduction');
is($step->summary, $hint->summary, 'step applies the same deduction hint would have returned');
is($grid->cell_from_row_column(0, 0)->value, 1, 'step applies the deduction');
is($solver->deduction_count, $deductions_before + 1, 'step records the deduction');

my $no_progress_solver = Solver->new(
    strategy_classes => [ 'Local::Hint::NoProgress' ],
);
my $no_progress = $no_progress_solver->hint($grid);
ok(!defined $no_progress, 'hint returns undef when no strategy can produce a deduction');

my $bad_grid = eval { $solver->hint('not a grid'); 1 };
ok(!$bad_grid, 'hint rejects non-Grid values');
like($@, qr/Grid object/, 'hint reports Grid requirement');

done_testing();
