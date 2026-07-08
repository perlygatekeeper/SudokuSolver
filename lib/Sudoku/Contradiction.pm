package Sudoku::Contradiction;

use strict;
use warnings;

use Moose;

=head1 NAME

Sudoku::Contradiction - Structured description of an impossible Sudoku state

=head1 DESCRIPTION

A Contradiction records why a puzzle state can no longer lead to a valid
solution.  It is deliberately small and presentation-neutral so the Solver,
CLI, Hint, Explain, and future search/backtracking code can all react to the
same object.

=cut

has 'kind' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'message' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'cell' => (
    is        => 'ro',
    isa       => 'Maybe[Object]',
    predicate => 'has_cell',
);

has 'cells' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'unit' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_unit',
);

has 'value' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_value',
);

has 'explanation' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

sub location {
    my ($self) = @_;

    return q{} unless $self->has_cell;

    return sprintf 'R%dC%d', $self->cell->row + 1, $self->cell->column + 1;
}

sub summary {
    my ($self) = @_;

    my @parts = ( $self->kind, $self->message );

    push @parts, $self->location if $self->has_cell;
    push @parts, 'unit=' . $self->unit if $self->has_unit;
    push @parts, 'value=' . $self->value if $self->has_value;

    return join q{ }, @parts;
}

__PACKAGE__->meta->make_immutable;

1;
