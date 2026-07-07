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

sub run {
  my ( $self, %options ) = @_;

  my $puzzle_string = $self->puzzle_string_from_options(%options);

  print "puzzle_string: $puzzle_string\n";

  my $puzzle = Grid->new;
  $puzzle->load_from_string($puzzle_string);

  my($progress);
  my($pass_progress) = 1;
  my($pass) = 0;

  while ( $puzzle->solved <= 80 and $pass_progress ) {
    print "==== Pass " . ++$pass . " ====\n";
    $pass_progress = 0;
    $puzzle->big_print;

    # Naked Singles
    while ( $puzzle->solved <= 80 and $progress = $puzzle->find_and_set_naked_singles ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
#     $puzzle->pretty_print;
#     $puzzle->multi_column_status;
      $puzzle->big_print;
      $pass_progress += $progress;
      print "---- end naked singles method ----\n\n";
    }

    # Hidden Singles
    while ( $puzzle->solved <= 80 and $progress = $puzzle->find_and_set_hidden_singles ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
#     $puzzle->pretty_print;
#     $puzzle->multi_column_status;
      $puzzle->big_print;
      $pass_progress += $progress;
      print "---- end hidden singles method ----\n\n";
    }

    # Pointing / Claiming
    while ( $puzzle->solved <= 80 and $progress = $puzzle->find_pointing_claiming ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
      $puzzle->big_print;
      $pass_progress += $progress;
      print "---- end pointing / claiming processing ----\n\n";
    }

    # Naked Pairs
    while ( $puzzle->solved <= 80 and $progress = $puzzle->find_naked_pairs ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
      $puzzle->big_print;
      $pass_progress += $progress;
      print "---- end naked pairs processing ----\n\n";
    }

    # Hidden Pairs
    while ( $puzzle->solved <= 80 and $progress = $puzzle->find_hidden_pairs ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
      $puzzle->big_print;
      $pass_progress += $progress;
      print "---- end hidden pairs processing ----\n\n";
    }

    # X-Wing
#   while ( $puzzle->solved <= 80 and $progress = $puzzle->find_x_wings ) {
      print "So far we filled this many cells: " . $puzzle->solved . "\n";
      $puzzle->big_print;
      $progress = $puzzle->find_x_wings;
      $pass_progress += $progress;
      print "---- end an x-wing search ----\n\n";
#   }

    # Naked Triplets
    # XY Wings

    # Remote Pairs

    print "==== End Pass " . $pass . " (progress is $pass_progress) ====\n";

  }

  if ( $puzzle->solved == 81 ) {
    print "We have solved this puzzle.  Final solution is:\n";
    print $_->value foreach ( @{$puzzle->cells} );
    print "\n";
  } else {
    printf "We were able to determine %d cells.\n", $puzzle->solved;
    $puzzle->big_print;
  }

  return $puzzle;
}

1;
