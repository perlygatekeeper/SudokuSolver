package Solver;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Types;
use Cell;
use Grid;

has 'default_puzzle_file' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'Puzzles/sudoku17-first50.txt',
);

sub normalize_puzzle_string {
  my ( $self, $puzzle_string ) = @_;

  $puzzle_string =~ s/\s+//g;
  $puzzle_string =~ tr/./0/;

  die "Puzzle string must contain exactly 81 digits or dots\n"
    unless $puzzle_string =~ /^\d{81}$/;

  return $puzzle_string;
}

sub puzzle_strings_from_file {
  my ( $self, $puzzle_file ) = @_;

  open my $puzzle_fh, '<', $puzzle_file
      or die "Could not open '$puzzle_file': $!";

  my @puzzle_strings;
  while ( my $line = <$puzzle_fh> ) {
    next if ( $line =~ /^\s*$|^\s*#/ ); # skip white, blank and commented lines.
    chomp $line;
    $line =~ s/\s+//g;
    next unless length $line;
    push @puzzle_strings, $self->normalize_puzzle_string($line);
  }
  close $puzzle_fh;

  die "No puzzle strings found in '$puzzle_file'\n" unless @puzzle_strings;

  return @puzzle_strings;
}

sub puzzle_string_from_options {
  my ( $self, %options ) = @_;

  if ( defined $options{puzzle_string} ) {
    return $self->normalize_puzzle_string( $options{puzzle_string} );
  }

  my $puzzle_file  = $options{puzzle_file} // $self->default_puzzle_file;
  my $puzzle_index = $options{puzzle_index} // 1;

  my @puzzle_strings = $self->puzzle_strings_from_file($puzzle_file);

  die "Puzzle number must be between 1 and " . scalar(@puzzle_strings) . "\n"
    if $puzzle_index < 1 || $puzzle_index > @puzzle_strings;

  return $puzzle_strings[ $puzzle_index - 1 ];
}

1;
