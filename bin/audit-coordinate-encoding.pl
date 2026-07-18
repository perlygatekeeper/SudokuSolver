#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use JSON::PP;
use lib "$Bin/../lib";

use Sudoku::CoordinateEncoding qw(
    clue_count
    encode_puzzle
);

my @files = @ARGV;

if (!@files) {
    @files = grep { -e $_ }
        "$Bin/../Puzzles/Master/sudoku17-master.jsonl",
        "$Bin/../Puzzles/Master/sudoku17-master.jsonl.gz";
}

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
my $json = JSON::PP->new->utf8(1);

for my $file (@files) {
    my $fh = _open_input($file);

    my $line_number = 0;

    while (my $line = <$fh>) {
        ++$line_number;
        chomp $line;
        $line =~ s/\r\z//;
        next if $line =~ /\A\s*\z/;

        ++$puzzles;

        my $puzzle = _puzzle_from_line($line, $json);
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

sub _open_input {
    my ($path) = @_;

    if ($path =~ /\.gz\z/) {
        my $fh = IO::Uncompress::Gunzip->new($path)
            or die "Could not open compressed '$path': $GunzipError\n";
        return $fh;
    }

    open my $fh, '<', $path
        or die "Could not open '$path': $!\n";
    return $fh;
}

sub _puzzle_from_line {
    my ($line, $json) = @_;

    if ($line =~ /\A\s*\{/) {
        my $record = $json->decode($line);
        return $record->{identity}{canonical_puzzle}
            if exists $record->{identity}
            && exists $record->{identity}{canonical_puzzle};
        die "JSONL record does not contain identity.canonical_puzzle\n";
    }

    return $line;
}
