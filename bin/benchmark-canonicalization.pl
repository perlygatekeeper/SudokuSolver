#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use JSON::PP;
use Time::HiRes qw(time);

use lib 'lib';
use Sudoku::Canonical qw(canonicalize);

my $file = 'Puzzles/Master/sudoku17-master.jsonl.gz';
my $limit = 50;

GetOptions(
    'file=s'  => \$file,
    'limit=i' => \$limit,
) or die "Usage: $0 [--file FILE] [--limit N]\n";

die "--limit must be a positive integer\n"
    unless defined $limit && $limit =~ /\A\d+\z/ && $limit > 0;

my $json = JSON::PP->new->utf8(1);
my $fh = _open_input($file);

my $started = time;
my $processed = 0;

while (my $line = <$fh>) {
    $line =~ s/\r?\n\z//;
    next if $line =~ /\A\s*(?:#|\z)/;
    my $puzzle = _puzzle_from_line($line, $json);

    canonicalize($puzzle);
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

sub _open_input {
    my ($path) = @_;

    if ($path =~ /\.gz\z/) {
        my $fh = IO::Uncompress::Gunzip->new($path)
            or die "Cannot open compressed '$path': $GunzipError\n";
        return $fh;
    }

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";
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

    $line =~ tr/./0/;
    return $line;
}
