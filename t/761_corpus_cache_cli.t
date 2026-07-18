use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3;
use JSON::PP;
use Symbol qw(gensym);
use Test::More;

my $tmpdir = tempdir(CLEANUP => 1);
my $source = File::Spec->catfile($tmpdir, 'master.jsonl');
my $cache_file = File::Spec->catfile($tmpdir, 'master.sqlite');

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

open my $out, '>:raw', $source or die "Cannot create '$source': $!";
print {$out} JSON::PP->new->canonical(1)->encode(_record()), "\n";
close $out;

my ($build_output, $build_error, $build_exit) = _run_cache_builder(
    '--input'  => $source,
    '--output' => $cache_file,
);

is($build_exit, 0, 'cache builder exits successfully');
is($build_error, q{}, 'cache builder is quiet on stderr');
like($build_output, qr/^Built corpus cache: /m, 'cache builder reports created cache');
like($build_output, qr/^Records: 1$/m, 'cache builder reports record count');
ok(-s $cache_file, 'cache builder writes SQLite cache file');

my ($current_output, $current_error, $current_exit) = _run_cache_builder(
    '--input'  => $source,
    '--output' => $cache_file,
);

is($current_exit, 0, 'current cache check exits successfully');
is($current_error, q{}, 'current cache check is quiet on stderr');
like($current_output, qr/^Corpus cache is current: /m, 'builder reuses current cache');
like($current_output, qr/^Records: 1$/m, 'current cache reports record count');

done_testing();

sub _run_cache_builder {
    my (@args) = @_;

    my ($stdin, $stdout);
    my $stderr = gensym;
    my $pid = open3(
        $stdin,
        $stdout,
        $stderr,
        $^X,
        '-Ilib',
        'bin/build-corpus-cache.pl',
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
