use strict;
use warnings;
use v5.10;

use Solver;
my $puzzle = Solver-new;

$puzzle = load('filename.txt');
say $puzzle->grid;
