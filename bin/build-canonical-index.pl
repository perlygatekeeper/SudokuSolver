#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Getopt::Long qw(GetOptions);
use POSIX qw(_exit);

use lib 'lib';
use Sudoku::Canonical;
use Sudoku::CoordinateEncoding qw(encode_puzzle validate_puzzle_string);
use Sudoku::Symmetry;

my $file = 'Puzzles/Benchmarks_Corpus/17puz49158.txt';
my $output = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-index.tsv';
my $jobs = 1;
my $limit;

GetOptions(
    'file=s'   => \$file,
    'output=s' => \$output,
    'jobs=i'   => \$jobs,
    'limit=i'  => \$limit,
) or die _usage();

die "--jobs must be a positive integer\n"
    unless defined $jobs && $jobs =~ /\A\d+\z/ && $jobs > 0;
die "--limit must be a positive integer\n"
    if defined($limit) && ($limit !~ /\A\d+\z/ || $limit < 1);

my @puzzles = _read_puzzles($file, $limit);
die "No puzzles were read from '$file'\n" unless @puzzles;
$jobs = @puzzles if $jobs > @puzzles;

my $tmpdir = tempdir('sudoku-canonical-index-XXXXXX', TMPDIR => 1, CLEANUP => 1);
my @parts;
my @children;

for my $worker (0 .. $jobs - 1) {
    my $part = File::Spec->catfile($tmpdir, sprintf('part-%03d.tsv', $worker));
    push @parts, $part;

    my $pid = fork();
    die "Cannot fork canonical-index worker: $!\n" unless defined $pid;

    if ($pid == 0) {
        my $ok = eval {
            open my $fh, '>', $part or die "Cannot create '$part': $!\n";
            for (my $index = $worker; $index < @puzzles; $index += $jobs) {
                my $record = _canonical_record($index + 1, $puzzles[$index]);
                print {$fh} join("\t", @$record), "\n"
                    or die "Cannot write '$part': $!\n";
            }
            close $fh or die "Cannot close '$part': $!\n";
            1;
        };
        if (!$ok) {
            my $error = $@ || 'unknown worker failure';
            warn $error;
            _exit(1);
        }
        _exit(0);
    }

    push @children, $pid;
}

my $failed = 0;
for my $pid (@children) {
    waitpid($pid, 0);
    $failed = 1 if $? != 0;
}
die "One or more canonical-index workers failed\n" if $failed;

my @records;
for my $part (@parts) {
    open my $fh, '<', $part or die "Cannot open '$part': $!\n";
    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        my @fields = split /\t/, $line, -1;
        die "Malformed canonical-index worker record in '$part'\n"
            unless @fields == 5;
        push @records, \@fields;
    }
    close $fh or die "Cannot close '$part': $!\n";
}

@records = sort { $a->[0] <=> $b->[0] } @records;
die "Canonical-index worker count mismatch\n" unless @records == @puzzles;

my %fingerprints;
for my $expected (1 .. @records) {
    my ($ordinal, $source, $canonical, $fingerprint, $shorthand) =
        @{ $records[$expected - 1] };

    die "Canonical-index ordinal mismatch at record $expected\n"
        unless $ordinal == $expected;
    die "Canonical-index source mismatch at record $expected\n"
        unless $source eq $puzzles[$expected - 1];
    die "Canonical-index fingerprint mismatch at record $expected\n"
        unless $fingerprint eq encode_puzzle($canonical);

    my $transform = Sudoku::Symmetry->from_shorthand($shorthand);
    die "Canonical-index witness replay failed at record $expected\n"
        unless $transform->apply_puzzle($source) eq $canonical;

    if (exists $fingerprints{$fingerprint}) {
        die "Duplicate canonical fingerprint '$fingerprint' at records "
            . "$fingerprints{$fingerprint} and $expected\n";
    }
    $fingerprints{$fingerprint} = $expected;
}

my $temporary_output = "$output.tmp.$$";
open my $out, '>', $temporary_output
    or die "Cannot create '$temporary_output': $!\n";
print {$out} "# SudokuSolver canonical index v1\n";
print {$out} "# ordinal\tsource_puzzle\tcanonical_puzzle\tfingerprint\ttransform\n";
for my $record (@records) {
    print {$out} join("\t", @$record), "\n"
        or die "Cannot write '$temporary_output': $!\n";
}
close $out or die "Cannot close '$temporary_output': $!\n";
rename $temporary_output, $output
    or die "Cannot replace '$output' with '$temporary_output': $!\n";

printf "Canonical Index\n";
printf "===============\n\n";
printf "Input puzzles       : %d\n", scalar @puzzles;
printf "Unique fingerprints : %d\n", scalar keys %fingerprints;
printf "Workers             : %d\n", $jobs;
printf "Output              : %s\n", $output;
printf "Result              : PASS\n";

sub _canonical_record {
    my ($ordinal, $source) = @_;
    my $result = Sudoku::Canonical->canonical_form($source);

    return [
        $ordinal,
        $source,
        $result->puzzle,
        $result->fingerprint,
        $result->transform->serialize,
    ];
}

sub _read_puzzles {
    my ($path, $maximum) = @_;

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";
    my @items;
    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next if $line =~ /\A\s*(?:#|\z)/;
        $line =~ tr/./0/;
        push @items, validate_puzzle_string($line);
        last if defined($maximum) && @items >= $maximum;
    }
    close $fh or die "Cannot close '$path': $!\n";

    return @items;
}

sub _usage {
    return <<'USAGE';
Usage: build-canonical-index.pl [options]

  --file FILE       Source puzzle file
  --output FILE     Destination TSV index
  --jobs N          Parallel worker processes (default: 1)
  --limit N         Process only the first N puzzles
USAGE
}
