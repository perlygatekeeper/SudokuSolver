#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long;
use Solver;
use Grid;

my $file;
my $puzzle = 1;
my $string;
my $help;

GetOptions(
    'file|f=s'   => \$file,
    'puzzle|p=i' => \$puzzle,
    'string|s=s' => \$string,
    'help|h'     => \$help,
) or usage();

usage() if $help;

my $solver = Solver->new;

my $puzzle_string;

if (defined $string) {
    $puzzle_string = $solver->normalize_puzzle_string($string);
}
elsif (defined $file) {
    my @puzzles = $solver->puzzle_strings_from_file($file);

    die "Puzzle number must be >= 1\n"
        if $puzzle < 1;

    die "Puzzle number $puzzle not found in $file\n"
        if $puzzle > @puzzles;

    $puzzle_string = $puzzles[$puzzle - 1];
}
else {
    usage();
}

print "Puzzle string:\n";
print "$puzzle_string\n\n";

print "Length: ", length($puzzle_string), "\n\n";

my $grid = Grid->new;
$grid->load_from_string($puzzle_string);

$grid->big_print;

exit 0;

sub usage {
    print <<"USAGE";
Usage:
  bin/show_puzzle.pl --file FILE [--puzzle N]
  bin/show_puzzle.pl --string PUZZLE

Examples:
  bin/show_puzzle.pl --file Puzzles/Puzzle_Dispatch_20191209.txt
  bin/show_puzzle.pl --string 000000013000800070000502000000400900107000000000000200890000050040000600000010000

Options:
  -f, --file FILE       puzzle file
  -p, --puzzle N        1-based puzzle number from file, default 1
  -s, --string PUZZLE   puzzle string
  -h, --help            show this help

USAGE

    exit 0;
}
