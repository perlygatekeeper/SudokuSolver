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

# $puzzle = load('filename.txt');
# $puzzle->out;
$puzzle->pretty_print;


my( $this_cell, $progress );
print "\nShowing status of all cells:\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  $this_cell->show_my_possibilities;
}

print "\nLooking for cells with only one possible value left:\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  # check if this cell has only one possibility left, and if so set it and clear it's row, column and box neighboors.
  if ( $this_cell->possibilities->[0] == 1 ) {
    $progress++;
    my($value,) = grep { $_ != 0 } @{$this_cell->possibilities}[1..9];
    $this_cell->value($value);
    print "Setting cell @ "
      . ( $this_cell->row + 1 ) . ", "
      . ( $this_cell->column + 1 ) . ", "
      . ( $this_cell->box + 1 ) . " to "
      . $this_cell->value
      . "\n";
    $this_cell->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
    $puzzle->remove_my_solution_from_my_mates($this_cell);
  }
}
$puzzle->pretty_print;
print "\nSet $progress cells this pass.\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  $this_cell->show_my_possibilities;
}

print "\nLooking for cells with only one possible value left:\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  # check if this cell has only one possibility left, and if so set it and clear it's row, column and box neighboors.
  if ( $this_cell->possibilities->[0] == 1 ) {
    $progress++;
    my($value,) = grep { $_ != 0 } @{$this_cell->possibilities}[1..9];
    $this_cell->value($value);
    print "Setting cell @ "
      . ( $this_cell->row + 1 ) . ", "
      . ( $this_cell->column + 1 ) . ", "
      . ( $this_cell->box + 1 ) . " to "
      . $this_cell->value
      . "\n";
    $this_cell->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
    $puzzle->remove_my_solution_from_my_mates($this_cell);
  }
}
$puzzle->pretty_print;
print "\nSet $progress cells this pass.\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  $this_cell->show_my_possibilities;
}

print "\nLooking for cells with only one possible value left:\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  # check if this cell has only one possibility left, and if so set it and clear it's row, column and box neighboors.
  if ( $this_cell->possibilities->[0] == 1 ) {
    $progress++;
    my($value,) = grep { $_ != 0 } @{$this_cell->possibilities}[1..9];
    $this_cell->value($value);
    print "Setting cell @ "
      . ( $this_cell->row + 1 ) . ", "
      . ( $this_cell->column + 1 ) . ", "
      . ( $this_cell->box + 1 ) . " to "
      . $this_cell->value
      . "\n";
    $this_cell->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
    $puzzle->remove_my_solution_from_my_mates($this_cell);
  }
}
$puzzle->pretty_print;
print "\nSet $progress cells this pass.\n\n";
foreach $this_cell ( @{ $puzzle->cells } ) {
  $this_cell->show_my_possibilities;
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
