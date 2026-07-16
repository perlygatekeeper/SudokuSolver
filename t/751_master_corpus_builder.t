use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku::CoordinateEncoding qw(encode_puzzle);

my $tmpdir = tempdir(CLEANUP => 1);
my $solutions = File::Spec->catfile($tmpdir, 'solutions.tsv');
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');

my $puzzle = '000000000000000001000002030000003020001040000005000060030000004070080009620007000';
my $solution = '953168742862734951417952836746893125281645397395271468138529674574386219629417583';
my $fingerprint = encode_puzzle($puzzle);
my $transform = 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012';

open my $out, '>', $solutions or die "Cannot create '$solutions': $!";
print {$out} "# fixture\n";
print {$out} join("\t",
    '17C-000001', $fingerprint, $puzzle, $solution, 1, $puzzle, $transform
), "\n";
close $out;

is system($^X, '-Ilib', 'bin/build-master-corpus.pl',
        '--input', $solutions, '--output', $master),
    0, 'master corpus builder succeeds';

open my $fh, '<:raw', $master or die "Cannot open '$master': $!";
my @lines = grep { /\S/ } <$fh>;
close $fh;
is scalar(@lines), 1, 'one JSON object written per input record';

my $record = JSON::PP->new->decode($lines[0]);
is $record->{schema}{version}, '1.0', 'schema version stored';
is $record->{identity}{canonical_id}, '17C-000001', 'canonical ID stored';
is $record->{identity}{fingerprint}, $fingerprint, 'fingerprint stored';
is $record->{identity}{canonical_puzzle}, $puzzle, 'canonical puzzle stored';
is $record->{solution}, $solution, 'solution stored';
is $record->{clue_count}, 17, 'clue count stored';
is $record->{canonicalization}{scheme_version}, '1.0',
    'canonicalization scheme version is independent';
is $record->{difficulty}{scheme}, 'SudokuSolver', 'difficulty scheme named';
ok !defined($record->{difficulty}{scheme_version}),
    'difficulty scheme version remains null until rating enrichment';
ok !defined($record->{difficulty}{score}), 'difficulty score remains null';
ok !defined($record->{pattern_symmetries}),
    'pattern symmetries remain null until analysis';
is $record->{provenance}{source_ordinal}, 1, 'source ordinal stored';
is $record->{provenance}{source_puzzle}, $puzzle, 'source puzzle stored';
is $record->{provenance}{witness_transform}, $transform,
    'witness transform stored';

done_testing();
