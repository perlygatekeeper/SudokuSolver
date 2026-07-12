package Sudoku::Statistics;

use strict;
use warnings;

use Moose;
use Scalar::Util qw(blessed);

use Sudoku::Deduction;

my %STRATEGY_RANK = (
    'Naked Singles'            => 1,
    'Hidden Singles'           => 2,
    'Pointing / Claiming'      => 3,
    'Naked Pairs'              => 4,
    'Hidden Pairs'             => 4,
    'Naked Triples'            => 5,
    'Hidden Triples'           => 5,
    'Naked Quads'              => 6,
    'Hidden Quads'             => 6,
    'X-Wing'                   => 7,
    'Swordfish'                 => 8,
    'Skyscraper'               => 9,
    'Two-String Kite'           => 10,
    'Empty Rectangle'           => 11,
    'Simple Coloring'           => 12,
    'X-Chains'                 => 13,
    'Multi-Coloring'           => 14,
    'Remote Pairs'             => 15,
    'XY-Wing'                  => 16,
    'XYZ-Wing'                 => 17,
    'WXYZ-Wing'                => 18,
    'XY-Chains'                 => 19,
    'Unique Rectangle Type 1'  => 20,
    'Unique Rectangle Type 2'  => 21,
);

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


sub contribution_by_strategy {
    my ($self) = @_;

    my %contributions;

    for my $deduction ( @{ $self->deductions } ) {
        my $strategy = $deduction->strategy;
        my $entry = $contributions{$strategy} ||= {
            deductions            => 0,
            cells_solved          => 0,
            candidates_eliminated => 0,
        };

        $entry->{deductions}++;

        if ( $deduction->action eq 'set_value' ) {
            $entry->{cells_solved}++;
        }
        elsif ( $deduction->action eq 'remove_candidate' ) {
            $entry->{candidates_eliminated}++;
        }
    }

    return \%contributions;
}

sub strategy_contribution {
    my ( $self, $strategy ) = @_;

    my $contribution = $self->contribution_by_strategy->{$strategy};

    return {
        deductions            => 0,
        cells_solved          => 0,
        candidates_eliminated => 0,
    } unless $contribution;

    return { %{$contribution} };
}

sub strategies_used {
    my ($self) = @_;

    return sort keys %{ $self->count_by_strategy };
}

sub actions_used {
    my ($self) = @_;

    return sort keys %{ $self->count_by_action };
}

sub highest_strategy {
    my ($self) = @_;

    my @strategies = $self->strategies_used;
    return undef unless @strategies;

    my ($highest) = sort {
        ( $STRATEGY_RANK{$b} // 0 ) <=> ( $STRATEGY_RANK{$a} // 0 )
            || $a cmp $b
    } @strategies;

    return $highest;
}

sub strategy_rank {
    my ( $self, $strategy ) = @_;

    return $STRATEGY_RANK{$strategy} // 0;
}

sub as_hash {
    my ($self) = @_;

    return {
        total_deductions   => $self->total_deductions,
        value_placements   => $self->value_placements,
        candidate_removals => $self->candidate_removals,
        by_strategy        => $self->count_by_strategy,
        by_action          => $self->count_by_action,
        by_strategy_action => $self->contribution_by_strategy,
        highest_strategy   => $self->highest_strategy,
    };
}

__PACKAGE__->meta->make_immutable;

1;
