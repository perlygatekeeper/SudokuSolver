package Sudoku::Hypothetical::Result;

use strict;
use warnings;

use Moose;

has 'status' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'assumption' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'grid' => (
    is       => 'ro',
    isa      => 'Object',
    required => 1,
);

has 'steps' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);

has 'deductions' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'history' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has 'contradiction' => (
    is        => 'ro',
    isa       => 'Maybe[Object]',
    predicate => 'has_contradiction',
);

sub placements {
    my ($self) = @_;

    return [ grep { $_->action eq 'set_value' } @{ $self->deductions } ];
}

sub eliminations {
    my ($self) = @_;

    return [ grep { $_->action eq 'remove_candidate' } @{ $self->deductions } ];
}

sub reached_fixed_point {
    my ($self) = @_;
    return $self->status eq 'fixed_point';
}

sub reached_limit {
    my ($self) = @_;
    return $self->status eq 'limit';
}

sub solved {
    my ($self) = @_;
    return $self->status eq 'solved';
}

sub as_hash {
    my ($self) = @_;

    my %result = (
        status       => $self->status,
        assumption   => { %{ $self->assumption } },
        steps        => $self->steps,
        deductions   => [ @{ $self->deductions } ],
        placements   => $self->placements,
        eliminations => $self->eliminations,
        history      => [ @{ $self->history } ],
    );

    $result{contradiction} = $self->contradiction
        if $self->has_contradiction;

    return \%result;
}

__PACKAGE__->meta->make_immutable;

1;
