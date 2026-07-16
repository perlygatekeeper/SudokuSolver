package Sudoku::Canonical::Result;

use strict;
use warnings;

use Sudoku::CoordinateEncoding qw(encode_puzzle validate_puzzle_string);

sub new {
    my ($class, %args) = @_;

    die "canonical result puzzle is required\n"
        unless defined $args{puzzle};
    my $puzzle = validate_puzzle_string($args{puzzle});

    die "canonical result transform is required\n"
        unless ref($args{transform})
            && $args{transform}->isa('Sudoku::Symmetry');

    die "canonical result stage is required\n"
        unless defined $args{stage} && !ref($args{stage}) && length $args{stage};

    return bless {
        puzzle    => $puzzle,
        transform => $args{transform},
        stage     => $args{stage},
    }, $class;
}

sub puzzle    { return $_[0]->{puzzle} }
sub transform { return $_[0]->{transform} }
sub stage     { return $_[0]->{stage} }

sub coordinate_encoding {
    my ($self) = @_;
    return encode_puzzle($self->{puzzle});
}

sub fingerprint {
    my ($self) = @_;
    die "fingerprint is available only for a canonical result\n"
        unless $self->{stage} eq 'canonical';
    return $self->coordinate_encoding;
}

1;
