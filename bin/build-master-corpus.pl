#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

use lib 'lib';
use Sudoku::CoordinateEncoding qw(encode_puzzle clue_count validate_puzzle_string);
use Sudoku::Symmetry;

my $input  = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-solutions.tsv';
my $output = 'Puzzles/Master/sudoku17-master.jsonl';
my $limit  = 0;

GetOptions(
    'input=s'  => \$input,
    'output=s' => \$output,
    'limit=i'  => \$limit,
) or die _usage();

die "--limit must be zero or a positive integer\n" if $limit < 0;

my @records = _read_solution_index($input);
splice @records, $limit if $limit && @records > $limit;
die "No canonical solution records were read from '$input'\n" unless @records;

my $json = JSON::PP->new->canonical(1)->utf8(1);
my $directory = dirname($output);
make_path($directory) if length($directory) && !-d $directory;
my $temporary_output = "$output.tmp.$$";
open my $out, '>:raw', $temporary_output
    or die "Cannot create '$temporary_output': $!\n";

for my $record (@records) {
    my $master_record = {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => $record->{canonical_id},
            fingerprint      => $record->{fingerprint},
            canonical_puzzle => $record->{canonical_puzzle},
        },
        solution  => $record->{solution},
        clue_count => clue_count($record->{canonical_puzzle}),
        canonicalization => {
            scheme         => 'SudokuSolver',
            scheme_version => '1.0',
        },
        difficulty => {
            scheme           => 'SudokuSolver',
            scheme_version   => undef,
            score            => undef,
            label            => undef,
            highest_strategy => undef,
        },
        pattern_symmetries => undef,
        provenance => {
            source_ordinal   => $record->{source_ordinal},
            source_puzzle    => $record->{source_puzzle},
            witness_transform => $record->{transform},
        },
    };

    print {$out} $json->encode($master_record), "\n"
        or die "Cannot write '$temporary_output': $!\n";
}

close $out or die "Cannot close '$temporary_output': $!\n";
rename $temporary_output, $output
    or die "Cannot replace '$output' with '$temporary_output': $!\n";

printf "Master Corpus JSONL\n";
printf "===================\n\n";
printf "Input records       : %d\n", scalar @records;
printf "First canonical ID  : %s\n", $records[0]{canonical_id};
printf "Last canonical ID   : %s\n", $records[-1]{canonical_id};
printf "Schema version      : 1.0\n";
printf "Output              : %s\n", $output;
printf "Result              : PASS\n";

sub _read_solution_index {
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";
    my @items;
    my (%ids, %fingerprints, %canonicals);
    my $previous_id;

    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next if $line =~ /\A\s*(?:#|\z)/;

        my @fields = split /\t/, $line, -1;
        die "Malformed canonical solution record in '$path'\n"
            unless @fields == 7;
        my ($id, $fingerprint, $canonical, $solution, $ordinal, $source, $transform) = @fields;

        die "Invalid canonical ID '$id' in '$path'\n"
            unless $id =~ /\A[A-Z0-9]+-\d{6,}\z/;
        die "Canonical IDs are not in ascending order at '$id'\n"
            if defined($previous_id) && $id le $previous_id;
        $previous_id = $id;

        die "Duplicate canonical ID '$id' in '$path'\n" if $ids{$id}++;
        die "Duplicate canonical fingerprint '$fingerprint' in '$path'\n"
            if $fingerprints{$fingerprint}++;
        die "Duplicate canonical puzzle in '$path'\n" if $canonicals{$canonical}++;
        die "Invalid source ordinal '$ordinal' in '$path'\n"
            unless $ordinal =~ /\A[1-9]\d*\z/;

        $canonical = validate_puzzle_string($canonical);
        $source    = validate_puzzle_string($source);
        die "Canonical puzzle $id does not contain exactly 17 clues\n"
            unless clue_count($canonical) == 17;
        die "Fingerprint mismatch for canonical ID $id\n"
            unless $fingerprint eq encode_puzzle($canonical);
        die "Invalid solution for canonical ID $id\n"
            unless defined($solution) && $solution =~ /\A[1-9]{81}\z/;

        for my $index (0 .. 80) {
            my $clue = substr($canonical, $index, 1);
            next if $clue eq '0';
            die "Solution conflicts with clue at cell " . ($index + 1)
                . " for canonical ID $id\n"
                unless substr($solution, $index, 1) eq $clue;
        }

        die "Witness replay failed for canonical ID $id\n"
            unless Sudoku::Symmetry->from_shorthand($transform)
                ->apply_puzzle($source) eq $canonical;

        push @items, {
            canonical_id     => $id,
            fingerprint      => $fingerprint,
            canonical_puzzle => $canonical,
            solution         => $solution,
            source_ordinal   => 0 + $ordinal,
            source_puzzle    => $source,
            transform        => $transform,
        };
    }
    close $fh or die "Cannot close '$path': $!\n";

    return @items;
}

sub _usage {
    return <<'USAGE';
Usage: build-master-corpus.pl [options]

  --input FILE      Solution-enriched canonical TSV
  --output FILE     Destination authoritative JSONL corpus
  --limit N         Process only the first N records (0 means all)
USAGE
}
