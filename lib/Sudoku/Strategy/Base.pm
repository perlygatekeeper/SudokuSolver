package Sudoku::Strategy::Base;

use strict;
use warnings;

use Sudoku::Deduction;


# Strategy subclasses implement a discovery-only contract:
#
#     my @deductions = $strategy->apply($grid);
#
# A strategy may inspect the grid and return Sudoku::Deduction objects, but it
# must not print, set cell values, remove candidates, or otherwise mutate the
# puzzle directly. Solver is responsible for applying and recording deductions.

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub name {
    die 'name() not implemented by strategy class';
}

sub apply {
    die 'apply($grid) not implemented by strategy class';
}

sub _remove_candidate_deduction {
    my ( $self, $cell, $value, $reason, $explanation ) = @_;

    return Sudoku::Deduction->new(
        strategy    => $self->name,
        action      => 'remove_candidate',
        cell        => $cell,
        value       => $value,
        reason      => $reason // q{},
        explanation => $explanation // sprintf(
            'Remove candidate %d from R%dC%d.',
            $value,
            $cell->row + 1,
            $cell->column + 1,
        ),
    );
}

1;
