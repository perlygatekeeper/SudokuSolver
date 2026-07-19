#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);

use lib 'lib';
use Sudoku::CoordinateEncoding qw(encode_puzzle validate_puzzle_string);
use Sudoku::Symmetry;

my $input  = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-index.tsv';
my $output = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-identities.tsv';
my $prefix = '17C';

GetOptions(
    'input=s'  => \$input,
    'output=s' => \$output,
    'prefix=s' => \$prefix,
) or die _usage();

die "--prefix must contain only uppercase letters and digits\n"
    unless defined($prefix) && $prefix =~ /\A[A-Z0-9]+\z/;

my @records = _read_staging_index($input);
die "No canonical staging records were read from '$input'\n" unless @records;

@records = sort {
       $a->{canonical_puzzle} cmp $b->{canonical_puzzle}
    || $a->{fingerprint}      cmp $b->{fingerprint}
    || $a->{source_ordinal}   <=> $b->{source_ordinal}
} @records;

my $width = length scalar @records;
$width = 6 if $width < 6;

my (%ids, %fingerprints, %canonicals);
for my $index (0 .. $#records) {
    my $record = $records[$index];
    my $id = sprintf('%s-%0*d', $prefix, $width, $index + 1);

    die "Duplicate canonical ID '$id'\n" if $ids{$id}++;
    die "Duplicate canonical fingerprint '$record->{fingerprint}'\n"
        if $fingerprints{ $record->{fingerprint} }++;
    die "Duplicate canonical puzzle at source ordinal $record->{source_ordinal}\n"
        if $canonicals{ $record->{canonical_puzzle} }++;

    $record->{canonical_id} = $id;
}

my $directory = dirname($output);
make_path($directory) if length($directory) && !-d $directory;

my $temporary_output = "$output.tmp.$$";
open my $out, '>', $temporary_output
    or die "Cannot create '$temporary_output': $!\n";
print {$out} "# SudokuSolver canonical identities v1\n";
print {$out} "# canonical_id\tfingerprint\tcanonical_puzzle\tsource_ordinal\tsource_puzzle\ttransform\n";
for my $record (@records) {
    print {$out} join("\t",
        @{$record}{qw(
            canonical_id fingerprint canonical_puzzle source_ordinal
            source_puzzle transform
        )}
    ), "\n" or die "Cannot write '$temporary_output': $!\n";
}
close $out or die "Cannot close '$temporary_output': $!\n";
rename $temporary_output, $output
    or die "Cannot replace '$output' with '$temporary_output': $!\n";

printf "Canonical Identities\n";
printf "====================\n\n";
printf "Input records       : %d\n", scalar @records;
printf "First canonical ID  : %s\n", $records[0]{canonical_id};
printf "Last canonical ID   : %s\n", $records[-1]{canonical_id};
printf "Output              : %s\n", $output;
printf "Result              : PASS\n";

sub _read_staging_index {
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot open '$path': $!\n";
    my @items;
    my %source_ordinals;

    while (my $line = <$fh>) {
        $line =~ s/\r?\n\z//;
        next if $line =~ /\A\s*(?:#|\z)/;

        my ($ordinal, $source, $canonical, $fingerprint, $transform) =
            split /\t/, $line, -1;
        die "Malformed canonical staging record in '$path'\n"
            unless defined($transform) && split(/\t/, $line, -1) == 5;
        die "Invalid source ordinal '$ordinal' in '$path'\n"
            unless $ordinal =~ /\A[1-9]\d*\z/;
        die "Duplicate source ordinal '$ordinal' in '$path'\n"
            if $source_ordinals{$ordinal}++;

        $source    = validate_puzzle_string($source);
        $canonical = validate_puzzle_string($canonical);
        die "Fingerprint mismatch at source ordinal $ordinal\n"
            unless $fingerprint eq encode_puzzle($canonical);

        my $symmetry = Sudoku::Symmetry->from_shorthand($transform);
        die "Witness replay failed at source ordinal $ordinal\n"
            unless $symmetry->apply_puzzle($source) eq $canonical;

        push @items, {
            source_ordinal   => 0 + $ordinal,
            source_puzzle    => $source,
            canonical_puzzle => $canonical,
            fingerprint      => $fingerprint,
            transform        => $transform,
        };
    }
    close $fh or die "Cannot close '$path': $!\n";

    return @items;
}

sub _usage {
    return <<'USAGE';
Usage: build-canonical-identities.pl [options]

  --input FILE      Canonical staging-index TSV
  --output FILE     Destination canonical-identity TSV
  --prefix TEXT     Canonical ID prefix (default: 17C)
USAGE
}
