#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Deduction;
use Sudoku::Test qw(capture_stdout);

{
    package Local::SetValueStrategy;

    sub new {
        my ($class) = @_;
        return bless { calls => 0 }, $class;
    }

    sub name {
        return 'Local Test Strategy';
    }

    sub calls {
        return shift->{calls};
    }

    sub apply {
        my ( $self, $grid ) = @_;
        $self->{calls}++;

        return if $self->{calls} > 1;

        my $cell = $grid->cell_from_row_column(0, 0);

        return Sudoku::Deduction->new(
            strategy    => $self->name,
            action      => 'set_value',
            cell        => $cell,
            value       => 1,
            reason      => 'Local strategy test deduction.',
            explanation => 'The local test strategy sets one value.',
        );
    }
}

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $solver   = Solver->new;
my $strategy = Local::SetValueStrategy->new;
my $progress;

my $output = capture_stdout {
    $progress = $solver->run_strategy( $grid, $strategy );
};

is($progress, 1, 'run_strategy returns the number of applied deductions');
is($grid->cell_from_row_column(0, 0)->value, 1, 'run_strategy applies set_value deductions');
is($solver->deduction_count, 1, 'run_strategy records applied deductions');
is($strategy->calls, 2, 'run_strategy repeats until the strategy makes no further progress');
like($output, qr/end local test strategy processing/, 'run_strategy reports the strategy processing block');

my $no_progress = $solver->run_strategy( $grid, $strategy );
is($no_progress, 0, 'run_strategy reports no progress when the strategy has no deductions');

my $bad_grid = eval { $solver->run_strategy( 'not a grid', $strategy ); 1 };
ok(!$bad_grid, 'run_strategy rejects non-Grid values');
like($@, qr/Grid object/, 'run_strategy reports Grid requirement');

my $bad_strategy = eval { $solver->run_strategy( $grid, 'not a strategy' ); 1 };
ok(!$bad_strategy, 'run_strategy rejects non-strategy values');
like($@, qr/strategy object/, 'run_strategy reports strategy requirement');

done_testing();
