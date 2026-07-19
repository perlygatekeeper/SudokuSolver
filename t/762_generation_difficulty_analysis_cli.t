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
    '--corpus-file'     => $master,
    '--base-difficulty' => 'Easy',
    '--samples'         => 2,
    '--clues'           => 17,
    '--seed'            => 1,
    '--progress'        => 0,
);

is($exit, 0, 'generation difficulty analysis exits successfully');
is($error, q{}, 'generation difficulty analysis is quiet when progress is disabled');
like($output, qr/^Generation Difficulty Analysis$/m, 'analysis report has title');
like($output, qr/^Base criteria:\s+difficulty=Easy$/m, 'analysis report shows base criteria');
like($output, qr/^Base pool:\s+1$/m, 'analysis report shows base pool count');
like($output, qr/^Samples completed:\s+2$/m, 'analysis report shows completed samples');
like($output, qr/^\| Easy \| 2 \| 100\.00% \|$/m, 'analysis report counts final Easy puzzles');
like($output, qr/^\| Easy \| Easy \| 2 \| 100\.00% \|$/m, 'analysis report includes transition table');

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
        'bin/analyze-generation-difficulty.pl',
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
