#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Sudoku::CoordinateEncoding qw(
    clue_count
    encode_puzzle
);

my @files = @ARGV;

if (!@files) {
    @files = sort glob "$Bin/../Puzzles/Benchmarks_Corpus/sudoku17-??-1000.txt";
    push @files, sort glob "$Bin/../Puzzles/Benchmarks_Corpus/sudoku17-??-158.txt";
}

die "No corpus files supplied or found\n" unless @files;

my %seen;
my $puzzles = 0;
my $invalid = 0;
my $wrong_clue_count = 0;
my $duplicates = 0;

for my $file (@files) {
    open my $fh, '<', $file
        or die "Could not open '$file': $!\n";

    my $line_number = 0;

    while (my $line = <$fh>) {
        ++$line_number;
        chomp $line;
        $line =~ s/\r\z//;
        next if $line =~ /\A\s*\z/;

        ++$puzzles;

        my $puzzle = $line;
        $puzzle =~ s/\s+//g;
        $puzzle =~ s/[^1-9]/0/g;

        my $encoding;
        my $ok = eval {
            $encoding = encode_puzzle($puzzle);
            1;
        };

        if (!$ok) {
            ++$invalid;
            warn "$file line $line_number: $@";
            next;
        }

        if (clue_count($puzzle) != 17) {
            ++$wrong_clue_count;
            warn "$file line $line_number: expected 17 clues\n";
        }

        if (exists $seen{$encoding}) {
            ++$duplicates;
            warn "$file line $line_number: duplicate encoding; first seen at $seen{$encoding}\n";
        }
        else {
            $seen{$encoding} = "$file line $line_number";
        }
    }

    close $fh;
}

print "Coordinate Encoding Corpus Audit\n";
print "================================\n\n";
printf "Files processed       : %d\n", scalar @files;
printf "Puzzles processed     : %d\n", $puzzles;
printf "Unique encodings      : %d\n", scalar keys %seen;
printf "Malformed puzzles     : %d\n", $invalid;
printf "Wrong clue counts     : %d\n", $wrong_clue_count;
printf "Duplicate encodings   : %d\n", $duplicates;

my $pass =
       $puzzles == 49_158
    && !$invalid
    && !$wrong_clue_count
    && !$duplicates
    && keys(%seen) == 49_158;

print "\nResult                : ", ($pass ? 'PASS' : 'FAIL'), "\n";

exit($pass ? 0 : 1);
