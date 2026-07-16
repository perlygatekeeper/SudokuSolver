#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);

use lib 'lib';
use Solver;
use Sudoku::CoordinateEncoding qw(encode_puzzle validate_puzzle_string);
use Sudoku::Symmetry;

my $input  = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-identities.tsv';
my $output = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-solutions.tsv';
my $limit  = 0;

GetOptions(
    'input=s'  => \$input,
    'output=s' => \$output,
    'limit=i'  => \$limit,
) or die _usage();

die "--limit must be zero or a positive integer\n" if $limit < 0;

my @records = _read_identity_index($input);
splice @records, $limit if $limit && @records > $limit;
die "No canonical identity records were read from '$input'\n" unless @records;

my $solver = Solver->new(output_mode => 'quiet');
for my $record (@records) {
    $solver->clear_deductions;
    my $grid = $solver->run(
        puzzle_string => $record->{canonical_puzzle},
        output_mode   => 'quiet',
    );

    die "Canonical puzzle $record->{canonical_id} did not solve completely\n"
        unless $grid->solved == 81 && !$solver->has_contradiction;

    my $solution = join '', map { $_->value || 0 } @{ $grid->cells };
    die "Invalid solution for $record->{canonical_id}\n"
        unless $solution =~ /\A[1-9]{81}\z/;

    for my $index (0 .. 80) {
        my $clue = substr($record->{canonical_puzzle}, $index, 1);
        next if $clue eq '0';
        die "Solution conflicts with clue at cell " . ($index + 1)
            . " for $record->{canonical_id}\n"
            unless substr($solution, $index, 1) eq $clue;
    }

    $record->{solution} = $solution;
}

my $directory = dirname($output);
make_path($directory) if length($directory) && !-d $directory;
my $temporary_output = "$output.tmp.$$";
open my $out, '>', $temporary_output
    or die "Cannot create '$temporary_output': $!\n";
print {$out} "# SudokuSolver canonical solutions v1\n";
print {$out} "# canonical_id\tfingerprint\tcanonical_puzzle\tsolution\tsource_ordinal\tsource_puzzle\ttransform\n";
for my $record (@records) {
    print {$out} join("\t",
        @{$record}{qw(
            canonical_id fingerprint canonical_puzzle solution
            source_ordinal source_puzzle transform
        )}
    ), "\n" or die "Cannot write '$temporary_output': $!\n";
}
close $out or die "Cannot close '$temporary_output': $!\n";
rename $temporary_output, $output
    or die "Cannot replace '$output' with '$temporary_output': $!\n";

printf "Canonical Solutions\n";
printf "===================\n\n";
printf "Input records       : %d\n", scalar @records;
printf "First canonical ID  : %s\n", $records[0]{canonical_id};
printf "Last canonical ID   : %s\n", $records[-1]{canonical_id};
printf "Output              : %s\n", $output;
printf "Result              : PASS\n";

sub _read_identity_index {
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";
    my @items;
    my (%ids, %fingerprints, %canonicals);

    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next if $line =~ /\A\s*(?:#|\z)/;

        my @fields = split /\t/, $line, -1;
        die "Malformed canonical identity record in '$path'\n"
            unless @fields == 6;
        my ($id, $fingerprint, $canonical, $ordinal, $source, $transform) = @fields;

        die "Invalid canonical ID '$id' in '$path'\n"
            unless $id =~ /\A[A-Z0-9]+-\d{6,}\z/;
        die "Duplicate canonical ID '$id' in '$path'\n" if $ids{$id}++;
        die "Duplicate canonical fingerprint '$fingerprint' in '$path'\n"
            if $fingerprints{$fingerprint}++;
        die "Duplicate canonical puzzle in '$path'\n" if $canonicals{$canonical}++;
        die "Invalid source ordinal '$ordinal' in '$path'\n"
            unless $ordinal =~ /\A[1-9]\d*\z/;

        $canonical = validate_puzzle_string($canonical);
        $source    = validate_puzzle_string($source);
        die "Fingerprint mismatch for canonical ID $id\n"
            unless $fingerprint eq encode_puzzle($canonical);
        die "Witness replay failed for canonical ID $id\n"
            unless Sudoku::Symmetry->from_shorthand($transform)
                ->apply_puzzle($source) eq $canonical;

        push @items, {
            canonical_id     => $id,
            fingerprint      => $fingerprint,
            canonical_puzzle => $canonical,
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
Usage: build-canonical-solutions.pl [options]

  --input FILE      Canonical-identity TSV
  --output FILE     Destination solution-enriched TSV
  --limit N         Process only the first N records (0 means all)
USAGE
}
