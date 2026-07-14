#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Solver;
use Sudoku::Deduction;
use Sudoku::Explain;

{
    package Local::Explain::SetFirst;

    sub new { return bless {}, shift }
    sub name { return 'Local Explain First' }

    sub apply {
        my ( $self, $grid ) = @_;

        my $cell = $grid->cell_from_row_column(0, 0);
        return if $cell->value;

        return Sudoku::Deduction->new(
            strategy    => $self->name,
            action      => 'set_value',
            cell        => $cell,
            value       => 1,
            reason      => 'Only one value fits here.',
            explanation => 'Cell R1C1 must be 1 because only one value fits here.',
        );
    }
}

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $solver = Solver->new(
    strategy_classes => [ 'Local::Explain::SetFirst' ],
);

can_ok($solver, qw(explain_deduction explain_next));

my $hint = $solver->hint($grid);
isa_ok($hint, 'Sudoku::Deduction', 'hint provides a deduction for explanation');

is(
    $solver->explain_deduction($hint),
    'Cell R1C1 must be 1 because only one value fits here.',
    'explain_deduction returns the deduction explanation when present',
);

is(
    Sudoku::Explain->new->explain_deduction($hint),
    'Cell R1C1 must be 1 because only one value fits here.',
    'Sudoku::Explain formats a deduction explanation',
);

my $fallback = Sudoku::Deduction->new(
    strategy => 'Fallback Strategy',
    action   => 'set_value',
    cell     => $grid->cell_from_row_column(0, 1),
    value    => 2,
    reason   => 'Fallback reason.',
);

is(
    Sudoku::Explain->new->explain_deduction($fallback),
    'Fallback Strategy sets R1C2 to 2 - Fallback reason.',
    'explain_deduction builds fallback text when explanation is absent',
);

my $solved_before = $grid->solved;
my $value_before  = $grid->cell_from_row_column(0, 0)->value;
my $log_before    = $solver->deduction_count;

is(
    $solver->explain_next($grid),
    'Cell R1C1 must be 1 because only one value fits here.',
    'explain_next explains the next available deduction',
);

is($grid->solved, $solved_before, 'explain_next does not change solved count');
is($grid->cell_from_row_column(0, 0)->value, $value_before, 'explain_next does not apply the deduction');
is($solver->deduction_count, $log_before, 'explain_next does not record a deduction');

my $no_explanation = Solver->new(
    strategy_classes => [],
)->explain_next($grid);
ok(!defined $no_explanation, 'explain_next returns undef when no hint exists');

my $bad_deduction = eval { $solver->explain_deduction('not a deduction'); 1 };
ok(!$bad_deduction, 'explain_deduction rejects non-Deduction values');
like($@, qr/Sudoku::Deduction/, 'explain_deduction reports Deduction requirement');

done_testing();
