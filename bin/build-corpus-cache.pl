#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use File::Basename qw(dirname);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Sudoku::Corpus;

my $input;
my $output;
my $force;
my $help;

GetOptions(
    'input|source|file=s' => \$input,
    'output|cache-file=s' => \$output,
    'force'               => \$force,
    'help|h'              => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

$input //= _default_input();
$output //= _default_output_for($input);

my $cache_class = _require_sqlite_cache();

if (!$force
    && $cache_class->is_current(
        source_file => $input,
        cache_file  => $output,
    )) {
    my $cache = $cache_class->new(file => $output);
    say "Corpus cache is current: $output";
    say "Records: " . $cache->count;
    exit 0;
}

my $dir = dirname($output);
make_path($dir) if length($dir) && !-d $dir;

my $cache = $cache_class->build(
    source_file => $input,
    cache_file  => $output,
);

say "Built corpus cache: $output";
say "Source: $input";
say "Records: " . $cache->count;

exit 0;

sub _default_output_for {
    my ($source) = @_;

    my $cache = $source;
    $cache =~ s/\.gz\z//;
    $cache =~ s/\.jsonl\z/.sqlite/;
    return $cache;
}

sub _default_input {
    my $jsonl = 'Puzzles/Master/sudoku17-master.jsonl';
    my $gzip = "$jsonl.gz";

    return $jsonl if -e $jsonl;
    return $gzip  if -e $gzip;
    return $jsonl;
}

sub _require_sqlite_cache {
    my $ok = eval {
        require Sudoku::Corpus::SQLiteCache;
        1;
    };

    return 'Sudoku::Corpus::SQLiteCache' if $ok;

    die join q{},
        "SQLite corpus cache support requires DBI and DBD::SQLite.\n",
        "Install them for your Perl, for example with MacPorts:\n",
        "    sudo port install p5.34-dbi p5.34-dbd-sqlite\n",
        "Then rebuild the cache with:\n",
        "    make corpus-cache\n",
        "\nOriginal error:\n$@";
}

__END__

=head1 NAME

build-corpus-cache.pl - build a local SQLite cache for the master corpus

=head1 SYNOPSIS

  bin/build-corpus-cache.pl
  bin/build-corpus-cache.pl --input Puzzles/Master/sudoku17-master.jsonl.gz
  bin/build-corpus-cache.pl --input corpus.jsonl.gz --output corpus.sqlite --force

=head1 DESCRIPTION

Builds a generated SQLite cache from the authoritative master corpus JSONL or
JSONL.gz file. The JSONL corpus remains the source of truth; the SQLite file is
a local acceleration artifact for corpus lookup and filtering.

=head1 OPTIONS

=over 4

=item B<--input FILE>

Source master corpus JSONL or JSONL.gz file. Defaults to the same corpus file
used by C<Sudoku::Corpus>.

=item B<--output FILE>

SQLite cache file to write. Defaults to the source path with C<.jsonl> or
C<.jsonl.gz> replaced by C<.sqlite>.

=item B<--force>

Rebuild even when the existing cache matches the source file.

=item B<-h, --help>

Show this help.

=back
