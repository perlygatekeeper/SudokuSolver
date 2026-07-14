use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use IPC::Open3;
use Symbol qw(gensym);

my $tmpdir = tempdir(CLEANUP => 1);
my $output = "$tmpdir/formats.txt";

my ($stdin, $stdout);
my $stderr = gensym;
my $pid = open3(
    $stdin,
    $stdout,
    $stderr,
    $^X,
    '-Ilib',
    'bin/sudoku.pl',
    '--list-grid-formats',
    '--output-file',
    $output,
);
close $stdin;

my $captured_stdout = do { local $/; <$stdout> // q{} };
my $captured_stderr = do { local $/; <$stderr> // q{} };
waitpid $pid, 0;
my $exit = $? >> 8;

is($exit, 0, 'output-file command exits successfully');
is($captured_stdout, q{}, 'redirected command leaves standard output empty');
is($captured_stderr, q{}, 'successful redirection leaves standard error empty');
ok(-f $output, 'output file is created');

open my $fh, '<:encoding(UTF-8)', $output
    or die "Cannot read $output: $!";
my $text = do { local $/; <$fh> };
close $fh;

like($text, qr/^Available grid formats\n/m, 'discovery heading is written to file');
like($text, qr/^    pretty \(default\)$/m, 'default grid format is written to file');
like($text, qr/^    candidate-json$/m, 'complete discovery output is written to file');

my $version_output = "$tmpdir/version.txt";
my $version_status = system(
    $^X,
    '-Ilib',
    'bin/sudoku.pl',
    '--version',
    '--output-file',
    $version_output,
);
is($version_status >> 8, 0, 'version output can be redirected');

open my $version_fh, '<:encoding(UTF-8)', $version_output
    or die "Cannot read $version_output: $!";
my $version_text = do { local $/; <$version_fh> };
close $version_fh;
like($version_text, qr/^SudokuSolver \S+\n$/, 'version text is written to file');

done_testing;
