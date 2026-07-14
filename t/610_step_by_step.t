#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Deduction;

{
    package Local::Step::SetFirst;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Step First' }

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
            reason   => 'Local step test deduction.',
        );
    }
}

{
    package Local::Step::ShouldNotRun;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Step Should Not Run' }

    sub apply {
        $calls++;
        return;
    }
}

{
    package Local::Step::NoProgress;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Step No Progress' }

    sub apply {
        $calls++;
        return;
    }
}

{
    package Local::Step::SetSecond;

    our $calls = 0;

    sub new { return bless {}, shift }
    sub name { return 'Local Step Second' }

    sub apply {
        my ( $self, $grid ) = @_;
        $calls++;

        my $cell = $grid->cell_from_row_column(0, 1);
        return Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'set_value',
            cell     => $cell,
            value    => 2,
            reason   => 'Local second strategy deduction.',
        );
    }
}

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $solver = Solver->new(
    strategy_classes => [
        'Local::Step::SetFirst',
        'Local::Step::ShouldNotRun',
    ],
);

my $deduction = $solver->step($grid);

isa_ok($deduction, 'Sudoku::Deduction', 'step returns the applied deduction');
is($deduction->strategy, 'Local Step First', 'step returns the first successful deduction');
is($grid->cell_from_row_column(0, 0)->value, 1, 'step applies one deduction');
is($solver->deduction_count, 1, 'step records the applied deduction');
is($Local::Step::SetFirst::calls, 1, 'step calls the first strategy');
is($Local::Step::ShouldNotRun::calls, 0, 'step stops after the first successful strategy');

my $second_grid = Grid->new;
$second_grid->load_from_string('0' x 81);

my $second_solver = Solver->new(
    strategy_classes => [
        'Local::Step::NoProgress',
        'Local::Step::SetSecond',
    ],
);

my $second_deduction = $second_solver->step($second_grid);

isa_ok($second_deduction, 'Sudoku::Deduction', 'step can use a later strategy when earlier strategies fail');
is($second_deduction->strategy, 'Local Step Second', 'step returns the later successful strategy deduction');
is($second_grid->cell_from_row_column(0, 1)->value, 2, 'step applies the later strategy deduction');
is($Local::Step::NoProgress::calls, 1, 'step calls earlier failing strategies');
is($Local::Step::SetSecond::calls, 1, 'step calls the later successful strategy');

my $no_progress_solver = Solver->new(
    strategy_classes => [ 'Local::Step::NoProgress' ],
);
my $no_progress = $no_progress_solver->step($second_grid);
ok(!defined $no_progress, 'step returns undef when no strategy makes progress');

my $bad_grid = eval { $solver->step('not a grid'); 1 };
ok(!$bad_grid, 'step rejects non-Grid values');
like($@, qr/Grid object/, 'step reports Grid requirement');

done_testing();
