package Sudoku::Render::EventLog;

use strict;
use warnings;

use Scalar::Util qw(blessed);
use Sudoku::Render::Event;

sub new {
    my ($class) = @_;
    return bless { events => [] }, $class;
}

sub record {
    my ($self, $event, %args) = @_;

    if (!blessed($event) || !$event->isa('Sudoku::Render::Event')) {
        my $type = $event;
        $event = Sudoku::Render::Event->new(
            type => $type,
            data => \%args,
        );
    }

    my $recorded = $event->with_sequence(scalar(@{ $self->{events} }) + 1);
    push @{ $self->{events} }, $recorded;

    return $recorded;
}

sub events {
    my ($self) = @_;
    return [ @{ $self->{events} } ];
}

sub count {
    my ($self) = @_;
    return scalar @{ $self->{events} };
}

sub clear {
    my ($self) = @_;
    $self->{events} = [];
    return $self;
}

sub as_array {
    my ($self) = @_;
    return [ map { $_->as_hash } @{ $self->{events} } ];
}

1;
