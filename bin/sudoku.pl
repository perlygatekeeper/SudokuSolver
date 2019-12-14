#!/usr/bin/env perl 
# A perl script to read in, solve and output a sudoku puzzle.

use strict;
use warnings;
use v5.10;

use Grid;
use Data::Dump;

my $puzzle_string;
while (<DATA>) {
  next if (/^\s*$|^\s*#/); # skip white, blank and commented lines.
  chomp;
  $puzzle_string .= $_;
}

# print "puzzle_string: $puzzle_string\n";
my $puzzle = Grid->new;
$puzzle->load_from_string($puzzle_string);


# $puzzle->out;

my($this_cell);
my($progress) = 1;
# $puzzle->find_and_set_singletons;

while ( $puzzle->solved <= 80 and $progress ) {

  # Singletons
  while ( $puzzle->solved <= 80 and $progress = $puzzle->find_and_set_singletons ) {
    print "So far we filled this many cells: " . $puzzle->solved . "\n";
    print "\nSet $progress cells this pass.\n\n";
    $puzzle->pretty_print;
    $puzzle->status;
  }

  # Lone Representatives
  # Naked Pairs
  # Naked Triplets
  # XY Wings

}
if ( $puzzle->solved == 81 ) {
  print "We have solved this puzzle.  Final solution is:\n";
  print $_->value foreach ( @{$puzzle->cells} );
  print "\n";
} else {
  printf "We were able to determine %d cells.\n", $puzzle->solved;
}


1;
__END__
# Grid 01
003020600
900305001
001806400
008102900
700000008
006708200
002609500
800203009
005010300
