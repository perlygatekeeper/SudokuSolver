#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time);

use lib 'lib';
use Sudoku::Canonical qw(canonicalize);

my $file = 'Puzzles/Benchmarks_Corpus/sudoku17-first50.txt';
my $limit = 50;

GetOptions(
    'file=s'  => \$file,
    'limit=i' => \$limit,
) or die "Usage: $0 [--file FILE] [--limit N]\n";

die "--limit must be a positive integer\n"
    unless defined $limit && $limit =~ /\A\d+\z/ && $limit > 0;

open my $fh, '<', $file or die "Cannot open '$file': $!\n";

my $started = time;
my $processed = 0;

while (my $line = <$fh>) {
    $line =~ s/\r?\n\z//;
    next if $line =~ /\A\s*(?:#|\z)/;
    $line =~ tr/./0/;

    canonicalize($line);
    last if ++$processed >= $limit;
}

close $fh or die "Cannot close '$file': $!\n";
die "No puzzles were processed from '$file'\n" unless $processed;

my $elapsed = time - $started;
my $per_puzzle = $elapsed / $processed;
my $per_second = $processed / $elapsed;
my $corpus_seconds = $per_puzzle * 49_158;

printf "Canonicalization Benchmark\n";
printf "==========================\n\n";
printf "File                 : %s\n", $file;
printf "Puzzles processed    : %d\n", $processed;
printf "Elapsed seconds      : %.6f\n", $elapsed;
printf "Seconds per puzzle   : %.6f\n", $per_puzzle;
printf "Puzzles per second   : %.3f\n", $per_second;
printf "Estimated corpus time: %.2f hours (single process)\n", $corpus_seconds / 3600;
