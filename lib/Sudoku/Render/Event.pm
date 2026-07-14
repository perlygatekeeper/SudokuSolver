package Sudoku::Render::Event;

use strict;
use warnings;

my %KNOWN_TYPE = map { $_ => 1 } qw(
    pass_started
    strategy_result
    deduction
    restart
    pass_finished
    contradiction
    final_status
);

sub new {
    my ($class, %args) = @_;

    die "Event type is required\n"
        if !defined $args{type} || $args{type} eq q{};
    die "Unknown event type '$args{type}'\n"
        if !$KNOWN_TYPE{$args{type}};
    die "Event data must be a hash reference\n"
        if exists $args{data} && ref($args{data}) ne 'HASH';
    die "Event sequence must be a non-negative integer\n"
        if exists $args{sequence}
        && (!defined $args{sequence} || $args{sequence} !~ /^\d+$/);

    my $self = {
        schema_version => 1,
        type           => $args{type},
        sequence       => exists $args{sequence} ? 0 + $args{sequence} : undef,
        data           => { %{ $args{data} || {} } },
    };

    return bless $self, $class;
}

sub schema_version { return $_[0]->{schema_version}; }
sub type           { return $_[0]->{type}; }
sub sequence       { return $_[0]->{sequence}; }

sub data {
    my ($self) = @_;
    return { %{ $self->{data} } };
}

sub with_sequence {
    my ($self, $sequence) = @_;

    return __PACKAGE__->new(
        type     => $self->type,
        sequence => $sequence,
        data     => $self->data,
    );
}

sub as_hash {
    my ($self) = @_;

    my $hash = {
        schema_version => $self->schema_version,
        type           => $self->type,
        data           => $self->data,
    };
    $hash->{sequence} = $self->sequence if defined $self->sequence;

    return $hash;
}

sub known_types {
    return sort keys %KNOWN_TYPE;
}

1;
