use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Sudoku::CoordinateEncoding qw(encode_puzzle);
use Sudoku::Symmetry;

my $tmpdir = tempdir(CLEANUP => 1);
my $input = File::Spec->catfile($tmpdir, 'puzzles.txt');
my $single = File::Spec->catfile($tmpdir, 'single.tsv');
my $parallel = File::Spec->catfile($tmpdir, 'parallel.tsv');

my @fixture_puzzles = (
    '003020600900305001001806400008102900700000008006708200002609500800203009005010300',
    '200080300060070084030500209000105408000000000402706000301007040720040060004010003',
    '000000907000420180000705026100904000050000040000507009920108000034059000507000000',
);

open my $source, '>', $input or die "Cannot create '$input': $!";
my @selected_fixtures = @fixture_puzzles[0, 1];
print {$source} "$_\n" for @selected_fixtures;
close $source or die "Cannot close '$input': $!";
is scalar(@selected_fixtures), 2,
    'created a two-puzzle canonical-index fixture';

is system($^X, '-Ilib', 'bin/build-canonical-index.pl',
        '--file', $input, '--output', $single, '--jobs', 1),
    0, 'single-worker canonical index succeeds';

is system($^X, '-Ilib', 'bin/build-canonical-index.pl',
        '--file', $input, '--output', $parallel, '--jobs', 2),
    0, 'two-worker canonical index succeeds';

open my $one, '<', $single or die "Cannot open '$single': $!";
local $/;
my $single_text = <$one>;
close $one;
open my $two, '<', $parallel or die "Cannot open '$parallel': $!";
my $parallel_text = <$two>;
close $two;

is $parallel_text, $single_text,
    'canonical index is byte-identical regardless of worker count';

my @records = grep { $_ !~ /\A#/ && length }
    split /\n/, $single_text;
is scalar(@records), 2, 'index contains one record per source puzzle';

my %seen;
for my $record (@records) {
    my ($ordinal, $source_puzzle, $canonical, $fingerprint, $shorthand) =
        split /\t/, $record, -1;
    ok $ordinal =~ /\A[12]\z/, 'record has a stable source ordinal';
    is $fingerprint, encode_puzzle($canonical),
        'record fingerprint encodes the canonical puzzle';
    my $replayed = Sudoku::Symmetry->from_shorthand($shorthand)
        ->apply_puzzle($source_puzzle);
    is $replayed, $canonical,
        'record witness replays the canonical transformation';
    ok !$seen{$fingerprint}++, 'fixture fingerprints are unique';
}

done_testing();
