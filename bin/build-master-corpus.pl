#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

use lib 'lib';
use Solver;
use Sudoku::CoordinateEncoding qw(
    decode_encoding
    encode_puzzle
    clue_count
    validate_puzzle_string
);
use Sudoku::PatternSymmetry qw(pattern_symmetries);
use Sudoku::Symmetry;

my $input  = 'Puzzles/Benchmarks_Corpus/sudoku17-canonical-solutions.tsv';
my $output = 'Puzzles/Master/sudoku17-master.jsonl';
my $limit  = 0;
my $jobs   = 1;

GetOptions(
    'input=s'  => \$input,
    'output=s' => \$output,
    'limit=i'  => \$limit,
    'jobs=i'   => \$jobs,
) or die _usage();

die "--limit must be zero or a positive integer\n" if $limit < 0;
die "--jobs must be a positive integer\n" unless $jobs =~ /\A[1-9]\d*\z/;

my @records = _read_solution_index($input);
splice @records, $limit if $limit && @records > $limit;
die "No canonical solution records were read from '$input'\n" unless @records;

my $directory = dirname($output);
make_path($directory) if length($directory) && !-d $directory;
my $temporary_output = "$output.tmp.$$";

if ($jobs == 1 || @records == 1) {
    _write_master_records($temporary_output, \@records);
}
else {
    _write_master_records_parallel($temporary_output, \@records, $jobs);
}

rename $temporary_output, $output
    or die "Cannot replace '$output' with '$temporary_output': $!\n";

printf "Master Corpus JSONL\n";
printf "===================\n\n";
printf "Input records       : %d\n", scalar @records;
printf "First canonical ID  : %s\n", $records[0]{canonical_id};
printf "Last canonical ID   : %s\n", $records[-1]{canonical_id};
printf "Schema version      : 1.0\n";
printf "Jobs                : %d\n", $jobs;
printf "Output              : %s\n", $output;
printf "Result              : PASS\n";

sub _write_master_records {
    my ($path, $records) = @_;

    my $json = JSON::PP->new->canonical(1)->utf8(1);
    my $solver = Solver->new(output_mode => 'quiet');

    open my $out, '>:raw', $path
        or die "Cannot create '$path': $!\n";

    for my $record (@{$records}) {
        print {$out} $json->encode(_master_record($solver, $record)), "\n"
            or die "Cannot write '$path': $!\n";
    }

    close $out or die "Cannot close '$path': $!\n";
}

sub _write_master_records_parallel {
    my ($path, $records, $jobs) = @_;

    my @chunks = _record_chunks($records, $jobs);
    my @part_files = map { "$path.part.$_" } 0 .. $#chunks;
    my @children;

    for my $index (0 .. $#chunks) {
        my $pid = fork();
        die "Cannot fork worker $index: $!\n" unless defined $pid;

        if ($pid == 0) {
            eval {
                _write_master_records($part_files[$index], $chunks[$index]);
                1;
            } or do {
                warn $@;
                exit 1;
            };
            exit 0;
        }

        push @children, $pid;
    }

    my $failed = 0;
    for my $pid (@children) {
        waitpid($pid, 0);
        $failed ||= $?;
    }

    if ($failed) {
        unlink @part_files;
        die "One or more master-corpus workers failed\n";
    }

    open my $out, '>:raw', $path
        or die "Cannot create '$path': $!\n";

    for my $part (@part_files) {
        open my $in, '<:raw', $part
            or die "Cannot open worker output '$part': $!\n";
        while (my $line = <$in>) {
            print {$out} $line or die "Cannot write '$path': $!\n";
        }
        close $in or die "Cannot close '$part': $!\n";
    }

    close $out or die "Cannot close '$path': $!\n";
    unlink @part_files;
}

sub _record_chunks {
    my ($records, $jobs) = @_;

    $jobs = @$records if $jobs > @$records;
    my @chunks;
    my $base = int(@$records / $jobs);
    my $extra = @$records % $jobs;
    my $offset = 0;

    for my $index (0 .. $jobs - 1) {
        my $size = $base + ($index < $extra ? 1 : 0);
        push @chunks, [ @$records[$offset .. $offset + $size - 1] ];
        $offset += $size;
    }

    return @chunks;
}

sub _master_record {
    my ($solver, $record) = @_;

    my $difficulty = _difficulty_for_record($solver, $record);
    my @pattern_symmetries = pattern_symmetries($record->{canonical_puzzle});

    return {
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
            scheme_version   => $difficulty->{rating_version},
            score            => $difficulty->{score},
            label            => $difficulty->{label},
            highest_strategy => $difficulty->{highest_strategy},
        },
        pattern_symmetries => \@pattern_symmetries,
        provenance => {
            source_ordinal    => $record->{source_ordinal},
            source_puzzle     => $record->{source_puzzle},
            witness_transform => $record->{transform},
        },
    };
}

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
        die "Fingerprint decode mismatch for canonical ID $id\n"
            unless decode_encoding($fingerprint) eq $canonical;
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

sub _difficulty_for_record {
    my ($solver, $record) = @_;

    $solver->clear_deductions;
    my $grid = $solver->run(
        puzzle_string => $record->{canonical_puzzle},
        output_mode   => 'quiet',
    );

    die "Canonical puzzle $record->{canonical_id} did not solve completely\n"
        unless $grid->solved == 81 && !$solver->has_contradiction;

    my $solved_grid = join q{}, map { $_->value || 0 } @{ $grid->cells };
    die "Solver result differs from stored solution for $record->{canonical_id}\n"
        unless $solved_grid eq $record->{solution};

    return $solver->difficulty->as_hash;
}

sub _usage {
    return <<'USAGE';
Usage: build-master-corpus.pl [options]

  --input FILE      Solution-enriched canonical TSV
  --output FILE     Destination authoritative JSONL corpus
  --limit N         Process only the first N records (0 means all)
  --jobs N          Number of parallel enrichment workers
USAGE
}
