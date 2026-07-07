package Sudoku::Deduction;

use strict;
use warnings;

use Moose;

=head1 NAME

Sudoku::Deduction - Structured description of one logical Sudoku deduction

=head1 DESCRIPTION

A Deduction represents one logical action proposed or performed by a solving
strategy.  It is deliberately presentation-neutral so it can support solver
logs, hints, difficulty scoring, regression tests, and future UI/reporting.

This first version is intentionally small.  Strategies are not yet required to
return Deduction objects, but this module defines the shape they will migrate
toward.

=cut

has 'strategy' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'action' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'row' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_row',
);

has 'column' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_column',
);

has 'box' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_box',
);

has 'value' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_value',
);

has 'candidate' => (
    is        => 'ro',
    isa       => 'Maybe[Int]',
    predicate => 'has_candidate',
);

has 'cells' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'reason' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

has 'explanation' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
);

sub has_cell_location {
    my ($self) = @_;

    return $self->has_row && $self->has_column;
}

sub location {
    my ($self) = @_;

    return q{} unless $self->has_cell_location;

    return sprintf 'R%dC%d', $self->row + 1, $self->column + 1;
}

sub as_hash {
    my ($self) = @_;

    my %deduction = (
        strategy    => $self->strategy,
        action      => $self->action,
        cells       => $self->cells,
        reason      => $self->reason,
        explanation => $self->explanation,
    );

    for my $field (qw(row column box value candidate)) {
        my $predicate = "has_$field";
        $deduction{$field} = $self->$field if $self->$predicate;
    }

    return \%deduction;
}

sub summary {
    my ($self) = @_;

    my @parts = (
        $self->strategy,
        $self->action,
    );

    push @parts, $self->location if $self->has_cell_location;

    if ($self->has_value) {
        push @parts, 'value=' . $self->value;
    }
    elsif ($self->has_candidate) {
        push @parts, 'candidate=' . $self->candidate;
    }

    return join q{ }, @parts;
}

__PACKAGE__->meta->make_immutable;

1;
