use strict;
use warnings;

use File::Temp qw(tempfile);
use Test::More;

use lib 'lib';

use Sudoku::Config;

my ($fh, $file) = tempfile();
print {$fh} <<'CONFIG';
# SudokuSolver personal defaults
[sudoku]
output = puzzle
grid_format = worksheet
character-set = UNICODE-MIXED
color = always

[generate-puzzle]
difficulty = Medium
clues = 30
format = summary
CONFIG
close $fh;

my $config = Sudoku::Config->new(file => $file);

is($config->file, $file, 'config records its source file');

my %sudoku = $config->section('sudoku');
is($sudoku{output}, 'puzzle', 'config reads section values');
is($sudoku{'grid-format'}, 'worksheet', 'config normalizes underscore option names');
is($sudoku{'character-set'}, 'UNICODE-MIXED', 'config reads hyphenated option names');
is($sudoku{color}, 'always', 'config reads additional values');

my %generate = $config->defaults_for('generate-puzzle', qw(difficulty format));
is_deeply(
    \%generate,
    {
        difficulty => 'Medium',
        format     => 'summary',
    },
    'defaults_for returns only requested option names',
);

my %missing = Sudoku::Config->new(file => "$file.missing")->section('sudoku');
is_deeply(\%missing, {}, 'missing config file produces no defaults');

done_testing();
