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

print "puzzle_string: $puzzle_string\n";
# my $puzzle = Grid->new($puzzle_string);
my $puzzle = Grid->new;
$puzzle->load_from_string($puzzle_string);

# $puzzle = load('filename.txt');
$puzzle->pretty_print;
$puzzle->out;

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
