use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';
use Grid;

my $tmpdir = tempdir(CLEANUP => 1);
my $source = File::Spec->catfile($tmpdir, 'puzzles.txt');
my $staging = File::Spec->catfile($tmpdir, 'staging.tsv');
my $identities = File::Spec->catfile($tmpdir, 'identities.tsv');
my $solutions = File::Spec->catfile($tmpdir, 'solutions.tsv');

my @fixture_puzzles = (
    '003020600900305001001806400008102900700000008006708200002609500800203009005010300',
    '200080300060070084030500209000105408000000000402706000301007040720040060004010003',
    '000000907000420180000705026100904000050000040000507009920108000034059000507000000',
);

open my $src, '>', $source or die "Cannot create '$source': $!";
print {$src} "$_\n" for @fixture_puzzles;
close $src;
is scalar(@fixture_puzzles), 3, 'created three-puzzle solution fixture';

is system($^X, '-Ilib', 'tools/corpus-build/build-canonical-index.pl',
        '--file', $source, '--output', $staging, '--jobs', 2),
    0, 'staging index succeeds';
is system($^X, '-Ilib', 'tools/corpus-build/build-canonical-identities.pl',
        '--input', $staging, '--output', $identities),
    0, 'identity assignment succeeds';
is system($^X, '-Ilib', 'tools/corpus-build/build-canonical-solutions.pl',
        '--input', $identities, '--output', $solutions),
    0, 'solution enrichment succeeds';

open my $fh, '<', $solutions or die "Cannot open '$solutions': $!";
my @records = grep { $_ !~ /\A#/ && /\S/ } <$fh>;
close $fh;
is scalar(@records), 3, 'solution index contains one record per identity';

for my $line (@records) {
    chomp $line;
    my ($id, $fingerprint, $puzzle, $solution, $ordinal, $source_puzzle, $transform) =
        split /\t/, $line, -1;
    like $id, qr/\A17C-\d{6}\z/, 'permanent ID retained';
    like $solution, qr/\A[1-9]{81}\z/, 'complete solution stored';
    my $grid = Grid->new;
    $grid->load_from_string($solution);
    is $grid->solved, 81, 'stored solution is a completed grid';
    for my $i (0 .. 80) {
        my $clue = substr($puzzle, $i, 1);
        next if $clue eq '0';
        is substr($solution, $i, 1), $clue,
            "$id solution preserves canonical clue at cell " . ($i + 1);
    }
}

done_testing();
