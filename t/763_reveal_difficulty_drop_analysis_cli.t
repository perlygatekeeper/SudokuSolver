use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use JSON::PP;
use Symbol qw(gensym);
use Test::More;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');
my $csv = File::Spec->catfile($tmpdir, 'drops.csv');

my $puzzle =
      '000000013'
    . '000800070'
    . '000502000'
    . '000400900'
    . '107000000'
    . '000000200'
    . '890000050'
    . '040000600'
    . '000010000';

my $solution =
      '278649513'
    . '956831472'
    . '314572896'
    . '532467981'
    . '167298345'
    . '489153267'
    . '893726154'
    . '741385629'
    . '625914738';

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
print {$out} JSON::PP->new->canonical(1)->encode(_record()), "\n";
close $out;

my ($output, $error, $exit) = _run_analysis(
    '--corpus-file' => $master,
    '--samples'     => 1,
    '--runs'        => 1,
    '--max-reveals' => 1,
    '--output'      => $csv,
    '--progress'    => 0,
);

is($exit, 0, 'reveal difficulty drop analysis exits successfully');
is($error, q{}, 'reveal difficulty drop analysis is quiet when progress is disabled');
like($output, qr/^Reveal Difficulty Drop Statistics$/m, 'analysis report has title');
like($output, qr/^Sampled puzzles:\s+1$/m, 'analysis report shows sample count');
like($output, qr/^Runs per puzzle:\s+1$/m, 'analysis report shows run count');
like($output, qr/^CSV output:\s+\Q$csv\E$/m, 'analysis report shows CSV output path');
ok(-s $csv, 'analysis writes CSV output');

open my $csv_fh, '<:encoding(UTF-8)', $csv or die "Cannot read '$csv': $!";
my $csv_text = do { local $/; <$csv_fh> };
close $csv_fh;

like(
    $csv_text,
    qr/^sample_index,run_index,canonical_id,source_ordinal,base_label,/,
    'CSV output includes expected header',
);
like($csv_text, qr/^1,1,17C-000001,1,Easy,/m, 'CSV output includes the sampled record');
like($csv_text, qr/,Trivial,/, 'CSV output includes the target drop label');

done_testing();

sub _run_analysis {
    my (@args) = @_;

    my ($stdin, $stdout);
    my $stderr = gensym;
    my $pid = open3(
        $stdin,
        $stdout,
        $stderr,
        $^X,
        '-Ilib',
        'tools/analyze-reveal-difficulty-drops.pl',
        @args,
    );
    close $stdin;

    my $output = do { local $/; <$stdout> // q{} };
    my $error = do { local $/; <$stderr> // q{} };
    waitpid $pid, 0;
    my $exit = $? >> 8;

    return ($output, $error, $exit);
}

sub _record {
    return {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => '17C-000001',
            fingerprint      => 'fp-001',
            canonical_puzzle => $puzzle,
        },
        solution => $solution,
        clue_count => 17,
        canonicalization => {
            scheme         => 'SudokuSolver',
            scheme_version => '1.0',
        },
        difficulty => {
            scheme           => 'SudokuSolver',
            scheme_version   => '2.7',
            score            => 2,
            label            => 'Easy',
            highest_strategy => 'Hidden Singles',
        },
        pattern_symmetries => [],
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $puzzle,
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}
