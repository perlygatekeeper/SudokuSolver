#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Solver;
use Sudoku::Deduction;
use Sudoku::Test qw(capture_stdout);

our @CALLS;
our $HIGHER_SUCCEEDED;
our $EASIEST_AFTER_HIGHER;
our $HARDEST_SAW_RESTART;

{
    package Local::Restart::Easiest;

    sub new {
        return bless {}, shift;
    }

    sub name {
        return 'Easiest Test Strategy';
    }

    sub apply {
        my ( $self, $grid ) = @_;

        push @main::CALLS, 'easiest';
        $main::EASIEST_AFTER_HIGHER = 1 if $main::HIGHER_SUCCEEDED;

        return;
    }
}

{
    package Local::Restart::Higher;

    sub new {
        return bless {}, shift;
    }

    sub name {
        return 'Higher Test Strategy';
    }

    sub apply {
        my ( $self, $grid ) = @_;

        push @main::CALLS, 'higher';
        return if $main::HIGHER_SUCCEEDED;

        $main::HIGHER_SUCCEEDED = 1;

        my $cell = $grid->cell_from_row_column(0, 0);

        return Sudoku::Deduction->new(
            strategy    => $self->name,
            action      => 'set_value',
            cell        => $cell,
            value       => 1,
            reason      => 'Higher strategy test deduction.',
            explanation => 'The higher strategy makes one deduction.',
        );
    }
}

{
    package Local::Restart::Hardest;

    sub new {
        return bless {}, shift;
    }

    sub name {
        return 'Hardest Test Strategy';
    }

    sub apply {
        my ( $self, $grid ) = @_;

        push @main::CALLS, 'hardest';

        $main::HARDEST_SAW_RESTART = $main::EASIEST_AFTER_HIGHER;

        return;
    }
}

my $solver = Solver->new(
    strategy_classes => [
        'Local::Restart::Easiest',
        'Local::Restart::Higher',
        'Local::Restart::Hardest',
    ],
);

my $grid;
my $output = capture_stdout {
    $grid = $solver->run( puzzle_string => '0' x 81 );
};

isa_ok($grid, 'Grid', 'run returns a Grid object');
is($solver->deduction_count, 1, 'higher strategy deduction was applied and recorded');
is($grid->cell_from_row_column(0, 0)->value, 1, 'higher strategy deduction was applied');

is_deeply(
    \@CALLS,
    [ qw(easiest higher higher easiest higher hardest) ],
    'solver restarts from the easiest strategy after higher-tier progress',
);

ok(
    $HARDEST_SAW_RESTART,
    'solver restarted at the easiest strategy before trying a harder strategy',
);

like($output, qr/==== Pass 1 ====/, 'first pass is reported');
like($output, qr/==== Pass 2 ====/, 'second pass is reported after progress');

done_testing();
