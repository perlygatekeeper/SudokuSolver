use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use JSON::PP;
use Symbol qw(gensym);
use Test::More;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');
my $artifact = File::Spec->catfile($tmpdir, 'generated.json');

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

my $config = File::Spec->catfile($tmpdir, 'sudoku_solver.conf');
open my $config_out, '>:raw', $config or die "Cannot create '$config': $!";
print {$config_out} <<'CONFIG';
[generate-puzzle]
seed = 1
clues = 17
difficulty = Easy
format = json
CONFIG
close $config_out;

my ($json_output, $json_error, $json_exit) = _run_generate(
    '--corpus-file' => $master,
    '--seed'        => 1,
    '--clues'       => 17,
    '--difficulty'  => 'Easy',
    '--format'      => 'json',
);

is($json_exit, 0, 'solve-path json generation command exits successfully');
is($json_error, q{}, 'solve-path json generation command is quiet on stderr');

my $decoded = JSON::PP->new->decode($json_output);
like($decoded->{puzzle}, qr/\A[0-9]{81}\z/, 'json output includes generated puzzle');
like($decoded->{solution}, qr/\A[1-9]{81}\z/, 'json output includes transformed solution');
is($decoded->{provenance}{canonical_id}, '17C-000001', 'json output preserves canonical identity');
is($decoded->{provenance}{corpus_seed}, 1, 'base seed sets corpus seed');
is($decoded->{provenance}{symmetry_seed}, 2, 'base seed sets symmetry seed');
is($decoded->{provenance}{reveal_seed}, 3, 'base seed sets reveal seed');
is($decoded->{provenance}{final_clue_count}, 17, 'json output records final clue count');
is($decoded->{difficulty}{label}, 'Easy', 'json output records retained difficulty');

{
    local $ENV{SUDOKU_SOLVER_CONFIG} = $config;
    my ($config_output, $config_error, $config_exit) = _run_generate(
        '--corpus-file' => $master,
    );

    is($config_exit, 0, 'generate-puzzle config defaults exit successfully');
    is($config_error, q{}, 'generate-puzzle config defaults are quiet on stderr');
    my $config_decoded = JSON::PP->new->decode($config_output);
    is($config_decoded->{provenance}{final_clue_count}, 17, 'config supplies generator clue count');
    is($config_decoded->{difficulty}{label}, 'Easy', 'config supplies generator difficulty');
}

my ($summary_output, $summary_error, $summary_exit) = _run_generate(
    '--corpus-file' => $master,
    '--seed'        => 1,
    '--clues'       => 17,
    '--difficulty'  => 'Easy',
    '--format'      => 'summary',
    '--debug',
);

is($summary_exit, 0, 'solve-path debug command exits successfully');
like($summary_output, qr/^Generation mode:\s+solve-path$/m, 'summary identifies solve-path mode');
like($summary_output, qr/^Protected strategy:\s+Hidden Singles$/m, 'summary shows protected strategy');
like($summary_output, qr/^Difficulty:\s+Easy$/m, 'summary includes accepted difficulty');
like(
    $summary_error,
    qr/^Attempt 1: Starting with Corpus #1 \(17C-000001\), initial difficulty: Easy, protected strategy: Hidden Singles, target clues already present after 0 solve-path step\(s\), final difficulty: Easy, accept\.$/m,
    'debug command reports accepted solve-path attempt',
);

my ($worksheet_output, $worksheet_error, $worksheet_exit) = _run_generate(
    '--corpus-file' => $master,
    '--seed'        => 1,
    '--clues'       => 17,
    '--difficulty'  => 'Easy',
    '--format'      => 'worksheet',
);

is($worksheet_exit, 0, 'worksheet solve-path generation command exits successfully');
is($worksheet_error, q{}, 'worksheet solve-path generation command is quiet on stderr');
like($worksheet_output, qr/^  1 /m, 'worksheet output includes row labels');
like($worksheet_output, qr/┌/, 'worksheet output uses Unicode box drawing');

my ($file_output, $file_error, $file_exit) = _run_generate(
    '--corpus-file' => $master,
    '--seed'        => 1,
    '--clues'       => 17,
    '--difficulty'  => 'Easy',
    '--format'      => 'json',
    '--output-file' => $artifact,
);

is($file_exit, 0, 'output-file solve-path generation command exits successfully');
is($file_output, q{}, 'output-file command leaves stdout empty');
is($file_error, q{}, 'output-file command is quiet on stderr');
ok(-s $artifact, 'output-file command writes artifact');

my ($bad_output, $bad_error, $bad_exit) = _run_generate(
    '--corpus-file' => $master,
    '--format'      => 'workshet',
);

isnt($bad_exit, 0, 'unknown format exits with failure');
is($bad_output, q{}, 'unknown format emits no stdout');
like($bad_error, qr/Unknown format 'workshet'/, 'unknown format reports bad value');
like($bad_error, qr/Did you mean 'worksheet'\?/, 'unknown format suggests worksheet');

done_testing();

sub _run_generate {
    my (@args) = @_;

    my ($stdin, $stdout);
    my $stderr = gensym;
    my $pid = open3(
        $stdin,
        $stdout,
        $stderr,
        $^X,
        '-Ilib',
        'bin/generate-puzzle.pl',
        @args,
    );
    close $stdin;

    binmode $stdout, ':encoding(UTF-8)';
    binmode $stderr, ':encoding(UTF-8)';
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
