package Sudoku::GeneratedPuzzle;

use strict;
use warnings;

use Scalar::Util qw(blessed);

sub new {
    my ($class, %args) = @_;

    for my $required (qw(
        canonical_record corpus_seed symmetry_seed transform puzzle solution
    )) {
        die "$required is required\n" unless exists $args{$required};
    }
    die "transform must be a Sudoku::Symmetry object\n"
        unless blessed($args{transform}) && $args{transform}->isa('Sudoku::Symmetry');
    die "canonical_record must be a master corpus record\n"
        unless ref($args{canonical_record}) eq 'HASH'
            && ref($args{canonical_record}{identity}) eq 'HASH';

    return bless {
        canonical_record => $args{canonical_record},
        corpus_seed      => 0 + $args{corpus_seed},
        symmetry_seed    => 0 + $args{symmetry_seed},
        transform        => $args{transform},
        puzzle           => $args{puzzle},
        solution         => $args{solution},
    }, $class;
}

sub canonical_record { return $_[0]->{canonical_record} }
sub corpus_seed      { return $_[0]->{corpus_seed} }
sub symmetry_seed    { return $_[0]->{symmetry_seed} }
sub transform        { return $_[0]->{transform} }
sub puzzle           { return $_[0]->{puzzle} }
sub solution         { return $_[0]->{solution} }

sub canonical_id {
    my ($self) = @_;
    return $self->canonical_record->{identity}{canonical_id};
}

sub fingerprint {
    my ($self) = @_;
    return $self->canonical_record->{identity}{fingerprint};
}

sub canonical_puzzle {
    my ($self) = @_;
    return $self->canonical_record->{identity}{canonical_puzzle};
}

sub canonical_solution {
    my ($self) = @_;
    return $self->canonical_record->{solution};
}

sub transform_shorthand {
    my ($self) = @_;
    return $self->transform->serialize;
}

sub as_hash {
    my ($self) = @_;

    return {
        puzzle   => $self->puzzle,
        solution => $self->solution,
        provenance => {
            canonical_id       => $self->canonical_id,
            fingerprint        => $self->fingerprint,
            corpus_seed        => $self->corpus_seed,
            symmetry_seed      => $self->symmetry_seed,
            symmetry_transform => $self->transform_shorthand,
        },
    };
}

1;
