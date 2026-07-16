use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Sudoku::CoordinateEncoding qw(encode_puzzle);
use Sudoku::Symmetry;

my $tmpdir = tempdir(CLEANUP => 1);
my $source_file = File::Spec->catfile($tmpdir, 'puzzles.txt');
my $staging = File::Spec->catfile($tmpdir, 'staging.tsv');
my $reversed = File::Spec->catfile($tmpdir, 'reversed.tsv');
my $identities = File::Spec->catfile($tmpdir, 'identities.tsv');
my $identities_reversed = File::Spec->catfile($tmpdir, 'identities-reversed.tsv');

open my $source, '>', $source_file or die "Cannot create '$source_file': $!";
open my $corpus, '<', 'Puzzles/Benchmarks_Corpus/sudoku17-first50.txt'
    or die "Cannot open fixture corpus: $!";
my $written = 0;
while (my $line = <$corpus>) {
    next if $line =~ /\A\s*(?:#|\z)/;
    print {$source} $line;
    last if ++$written == 3;
}
close $corpus;
close $source;
is $written, 3, 'created a three-puzzle identity fixture';

is system($^X, '-Ilib', 'bin/build-canonical-index.pl',
        '--file', $source_file, '--output', $staging, '--jobs', 2),
    0, 'canonical staging index succeeds';

is system($^X, '-Ilib', 'bin/build-canonical-identities.pl',
        '--input', $staging, '--output', $identities),
    0, 'canonical identity assignment succeeds';

open my $in, '<', $staging or die "Cannot open '$staging': $!";
my @header;
my @records;
while (my $line = <$in>) {
    if ($line =~ /\A#/) { push @header, $line }
    else                 { push @records, $line }
}
close $in;
open my $rev, '>', $reversed or die "Cannot create '$reversed': $!";
print {$rev} @header, reverse @records;
close $rev;

is system($^X, '-Ilib', 'bin/build-canonical-identities.pl',
        '--input', $reversed, '--output', $identities_reversed),
    0, 'identity assignment succeeds for reordered staging input';

open my $one, '<', $identities or die "Cannot open '$identities': $!";
local $/;
my $identity_text = <$one>;
close $one;
open my $two, '<', $identities_reversed
    or die "Cannot open '$identities_reversed': $!";
my $reordered_text = <$two>;
close $two;

is $reordered_text, $identity_text,
    'canonical identities are independent of staging-record order';

my @identity_records = grep { $_ !~ /\A#/ && length }
    split /\n/, $identity_text;
is scalar(@identity_records), 3, 'identity index contains one record per puzzle';

my @canonicals;
for my $index (0 .. $#identity_records) {
    my ($id, $fingerprint, $canonical, $ordinal, $source_puzzle, $transform) =
        split /\t/, $identity_records[$index], -1;
    is $id, sprintf('17C-%06d', $index + 1),
        'canonical ID follows canonical-order sequence';
    is $fingerprint, encode_puzzle($canonical),
        'identity fingerprint encodes canonical puzzle';
    my $replayed = Sudoku::Symmetry->from_shorthand($transform)
        ->apply_puzzle($source_puzzle);
    is $replayed, $canonical, 'identity witness transform replays';
    ok $ordinal =~ /\A[123]\z/, 'source ordinal is retained as provenance';
    push @canonicals, $canonical;
}

is_deeply \@canonicals, [ sort @canonicals ],
    'permanent IDs are assigned by canonical puzzle ordering';

done_testing();
