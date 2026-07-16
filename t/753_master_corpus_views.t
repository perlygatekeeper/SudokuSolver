use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');
my $tsv = File::Spec->catfile($tmpdir, 'master.tsv');
my $summary = File::Spec->catfile($tmpdir, 'summary.txt');

my $record = {
    schema => {
        name    => 'SudokuSolver canonical corpus',
        version => '1.0',
    },
    identity => {
        canonical_id     => '17C-000001',
        fingerprint      => '2953-364892-384672-5579-63-6891-8296-85-89',
        canonical_puzzle => '000000000000000001000002030000003020001040000005000060030000004070080009620007000',
    },
    solution => '953168742862734951417952836746893125281645397395271468138529674574386219629417583',
    clue_count => 17,
    canonicalization => {
        scheme         => 'SudokuSolver',
        scheme_version => '1.0',
    },
    difficulty => {
        scheme           => 'SudokuSolver',
        scheme_version   => '2.7',
        score            => 11,
        label            => 'Master',
        highest_strategy => 'Digit Forcing Chains',
    },
    pattern_symmetries => [ 'rotation-180' ],
    provenance => {
        source_ordinal    => 1,
        source_puzzle     => '000000000000000001000002030000003020001040000005000060030000004070080009620007000',
        witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
    },
};

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
print {$out} JSON::PP->new->canonical(1)->encode($record), "\n";
close $out;

is system($^X, 'bin/export-master-corpus-views.pl',
        '--input', $master, '--tsv', $tsv, '--summary', $summary),
    0, 'master corpus view exporter succeeds';

open my $tsv_fh, '<:raw', $tsv or die "Cannot open '$tsv': $!";
my @tsv_lines = <$tsv_fh>;
close $tsv_fh;
is scalar(@tsv_lines), 2, 'TSV view has header and one data row';
like $tsv_lines[0], qr/\Acanonical_id\tfingerprint\tcanonical_puzzle/,
    'TSV header names identity columns first';
like $tsv_lines[1], qr/17C-000001\t.*\tMaster\t11\t2\.7\tDigit Forcing Chains\trotation-180/,
    'TSV row includes difficulty and pattern symmetry fields';

open my $summary_fh, '<:raw', $summary or die "Cannot open '$summary': $!";
my $summary_text = do { local $/; <$summary_fh> };
close $summary_fh;
like $summary_text, qr/Records: 1/, 'summary includes record count';
like $summary_text, qr/Master\s+1/, 'summary includes difficulty label count';
like $summary_text, qr/Digit Forcing Chains\s+1/,
    'summary includes highest-strategy count';
like $summary_text, qr/rotation-180\s+1/,
    'summary includes pattern-symmetry count';

done_testing();
