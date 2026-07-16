#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

my $input   = 'Puzzles/Master/sudoku17-master.jsonl';
my $tsv     = 'Puzzles/Master/sudoku17-master.tsv';
my $summary = 'Puzzles/Master/sudoku17-master-summary.txt';
my $limit   = 0;

GetOptions(
    'input=s'   => \$input,
    'tsv=s'     => \$tsv,
    'summary=s' => \$summary,
    'limit=i'   => \$limit,
) or die _usage();

die "--limit must be zero or a positive integer\n" if $limit < 0;

my @records = _read_master_records($input, $limit);
die "No master corpus records were read from '$input'\n" unless @records;

_write_tsv($tsv, \@records);
_write_summary($summary, \@records);

printf "Master Corpus Views\n";
printf "===================\n\n";
printf "Input records       : %d\n", scalar @records;
printf "First canonical ID  : %s\n", $records[0]{identity}{canonical_id};
printf "Last canonical ID   : %s\n", $records[-1]{identity}{canonical_id};
printf "TSV output          : %s\n", $tsv;
printf "Summary output      : %s\n", $summary;
printf "Result              : PASS\n";

sub _read_master_records {
    my ($path, $limit) = @_;

    open my $fh, '<:raw', $path or die "Cannot open '$path': $!\n";
    my $json = JSON::PP->new;
    my @records;
    my %ids;
    my $previous_id;

    while (my $line = <$fh>) {
        next unless $line =~ /\S/;
        my $record = $json->decode($line);
        _validate_record($record, $path);

        my $id = $record->{identity}{canonical_id};
        die "Canonical IDs are not in ascending order at '$id'\n"
            if defined($previous_id) && $id le $previous_id;
        $previous_id = $id;
        die "Duplicate canonical ID '$id' in '$path'\n" if $ids{$id}++;

        push @records, $record;
        last if $limit && @records >= $limit;
    }

    close $fh or die "Cannot close '$path': $!\n";
    return @records;
}

sub _validate_record {
    my ($record, $path) = @_;

    die "Malformed master corpus record in '$path'\n"
        unless ref($record) eq 'HASH'
            && ref($record->{identity}) eq 'HASH'
            && ref($record->{difficulty}) eq 'HASH'
            && ref($record->{pattern_symmetries}) eq 'ARRAY';

    die "Invalid canonical ID in '$path'\n"
        unless ($record->{identity}{canonical_id} // q{}) =~ /\A[A-Z0-9]+-\d{6,}\z/;
    die "Invalid canonical puzzle in '$path'\n"
        unless ($record->{identity}{canonical_puzzle} // q{}) =~ /\A[0-9]{81}\z/;
    die "Invalid solution in '$path'\n"
        unless ($record->{solution} // q{}) =~ /\A[1-9]{81}\z/;

    return 1;
}

sub _write_tsv {
    my ($path, $records) = @_;
    my @columns = qw(
        canonical_id fingerprint canonical_puzzle solution clue_count
        difficulty_label difficulty_score difficulty_scheme_version
        highest_strategy pattern_symmetries
    );

    _with_atomic_output($path, sub {
        my ($out) = @_;
        print {$out} join("\t", @columns), "\n";
        for my $record (@{$records}) {
            my $difficulty = $record->{difficulty};
            my @values = (
                $record->{identity}{canonical_id},
                $record->{identity}{fingerprint},
                $record->{identity}{canonical_puzzle},
                $record->{solution},
                $record->{clue_count},
                $difficulty->{label},
                $difficulty->{score},
                $difficulty->{scheme_version},
                $difficulty->{highest_strategy},
                join(',', @{ $record->{pattern_symmetries} }),
            );
            print {$out} join("\t", map { _tsv_field($_) } @values), "\n";
        }
    });
}

sub _write_summary {
    my ($path, $records) = @_;

    my (%difficulty_labels, %highest_strategies, %pattern_symmetries);
    for my $record (@{$records}) {
        $difficulty_labels{ $record->{difficulty}{label} // 'Unrated' }++;
        $highest_strategies{ $record->{difficulty}{highest_strategy} // 'none' }++;
        if (@{ $record->{pattern_symmetries} }) {
            $pattern_symmetries{$_}++ for @{ $record->{pattern_symmetries} };
        }
        else {
            $pattern_symmetries{'none'}++;
        }
    }

    _with_atomic_output($path, sub {
        my ($out) = @_;
        print {$out} "SudokuSolver Master Corpus Summary\n";
        print {$out} "===================================\n\n";
        print {$out} "Records: " . scalar(@{$records}) . "\n";
        print {$out} "First canonical ID: $records->[0]{identity}{canonical_id}\n";
        print {$out} "Last canonical ID: $records->[-1]{identity}{canonical_id}\n\n";

        _print_counts($out, 'Difficulty labels', \%difficulty_labels);
        _print_counts($out, 'Highest strategies', \%highest_strategies);
        _print_counts($out, 'Pattern symmetries', \%pattern_symmetries);
    });
}

sub _print_counts {
    my ($out, $heading, $counts) = @_;
    print {$out} "$heading\n";
    print {$out} "-" x length($heading), "\n";
    for my $name (sort { $counts->{$b} <=> $counts->{$a} || $a cmp $b } keys %{$counts}) {
        printf {$out} "%-36s %8d\n", $name, $counts->{$name};
    }
    print {$out} "\n";
}

sub _with_atomic_output {
    my ($path, $writer) = @_;
    my $directory = dirname($path);
    make_path($directory) if length($directory) && !-d $directory;
    my $temporary = "$path.tmp.$$";

    open my $out, '>:raw', $temporary
        or die "Cannot create '$temporary': $!\n";
    $writer->($out);
    close $out or die "Cannot close '$temporary': $!\n";
    rename $temporary, $path
        or die "Cannot replace '$path' with '$temporary': $!\n";
}

sub _tsv_field {
    my ($value) = @_;
    $value = q{} unless defined $value;
    $value =~ s/\\/\\\\/g;
    $value =~ s/\t/\\t/g;
    $value =~ s/\r/\\r/g;
    $value =~ s/\n/\\n/g;
    return $value;
}

sub _usage {
    return <<'USAGE';
Usage: export-master-corpus-views.pl [options]

  --input FILE      Authoritative master JSONL corpus
  --tsv FILE        Destination derived TSV view
  --summary FILE    Destination human-readable summary
  --limit N         Process only the first N records (0 means all)
USAGE
}
