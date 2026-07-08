package Sudoku::Statistics;

use strict;
use warnings;

use Moose;
use Scalar::Util qw(blessed);

use Sudoku::Deduction;

=head1 NAME

Sudoku::Statistics - Summary statistics for a SudokuSolver deduction log

=head1 DESCRIPTION

Sudoku::Statistics turns a list of Sudoku::Deduction objects into simple,
presentation-neutral counts.  It is intended to support console summaries,
reports, difficulty scoring, and future benchmarking without requiring callers
to know the internal shape of Solver's deduction log.

=cut

has 'deductions' => (
    is      => 'ro',
    isa     => 'ArrayRef[Sudoku::Deduction]',
    default => sub { [] },
);

sub from_solver {
    my ( $class, $solver ) = @_;

    die "from_solver requires an object with deductions()\n"
        unless blessed($solver) && $solver->can('deductions');

    return $class->new( deductions => [ @{ $solver->deductions } ] );
}

sub from_deductions {
    my ( $class, @deductions ) = @_;

    return $class->new( deductions => [ @deductions ] );
}

sub total_deductions {
    my ($self) = @_;

    return scalar @{ $self->deductions };
}

sub count_by_strategy {
    my ($self) = @_;

    my %counts;
    for my $deduction ( @{ $self->deductions } ) {
        $counts{ $deduction->strategy }++;
    }

    return \%counts;
}

sub count_by_action {
    my ($self) = @_;

    my %counts;
    for my $deduction ( @{ $self->deductions } ) {
        $counts{ $deduction->action }++;
    }

    return \%counts;
}

sub strategy_count {
    my ( $self, $strategy ) = @_;

    return $self->count_by_strategy->{$strategy} // 0;
}

sub action_count {
    my ( $self, $action ) = @_;

    return $self->count_by_action->{$action} // 0;
}

sub value_placements {
    my ($self) = @_;

    return $self->action_count('set_value');
}

sub candidate_removals {
    my ($self) = @_;

    return $self->action_count('remove_candidate');
}

sub strategies_used {
    my ($self) = @_;

    return sort keys %{ $self->count_by_strategy };
}

sub actions_used {
    my ($self) = @_;

    return sort keys %{ $self->count_by_action };
}

sub as_hash {
    my ($self) = @_;

    return {
        total_deductions  => $self->total_deductions,
        value_placements  => $self->value_placements,
        candidate_removals => $self->candidate_removals,
        by_strategy       => $self->count_by_strategy,
        by_action         => $self->count_by_action,
    };
}

__PACKAGE__->meta->make_immutable;

1;
