package Sudoku::CoordinateEncoding;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(
    encode_puzzle
    clue_count
    clue_locations
    validate_puzzle_string
);

sub validate_puzzle_string {
    my ($puzzle) = @_;

    if ( ref($puzzle) && $puzzle->can('as_puzzle_string') ) {
        $puzzle = $puzzle->as_puzzle_string;
    }

    die "Puzzle is required\n" unless defined $puzzle;
    die "Puzzle string must contain exactly 81 characters\n"
        unless length($puzzle) == 81;
    die "Puzzle string must contain only digits 0 through 9\n"
        unless $puzzle =~ /\A[0-9]{81}\z/;

    return $puzzle;
}

sub clue_count {
    my ($puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    return scalar grep { $_ ne '0' } split //, $puzzle;
}

sub clue_locations {
    my ($puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my @locations;

    for my $index (0 .. 80) {
        my $digit = substr($puzzle, $index, 1);
        next if $digit eq '0';

        push @locations, {
            digit  => 0 + $digit,
            row    => int($index / 9) + 1,
            column => ($index % 9) + 1,
        };
    }

    return wantarray ? @locations : \@locations;
}

sub encode_puzzle {
    my ($puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my @groups = map { q{} } 1 .. 9;

    for my $location (clue_locations($puzzle)) {
        $groups[ $location->{digit} - 1 ] .=
            $location->{row} . $location->{column};
    }

    my $encoding = join '-', @groups;

    _validate_generated_encoding($puzzle, $encoding);

    return $encoding;
}

sub _validate_generated_encoding {
    my ($puzzle, $encoding) = @_;

    my @groups = split /-/, $encoding, -1;
    die "Internal coordinate-encoding error: expected nine digit groups\n"
        unless @groups == 9;

    my $coordinates = join q{}, @groups;
    die "Internal coordinate-encoding error: malformed coordinate data\n"
        unless $coordinates =~ /\A[1-9]*\z/
            && length($coordinates) % 2 == 0;

    my $expected_length = clue_count($puzzle) * 2 + 8;
    die "Internal coordinate-encoding error: unexpected encoded length\n"
        unless length($encoding) == $expected_length;

    return 1;
}

1;
