#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

my $help = qx{$^X -Ilib bin/sudoku.pl --help 2>&1};
is($? >> 8, 0, '--help exits successfully');
like($help, qr/quiet\s+- machine-friendly, minimal output\./, 'help explains quiet mode');
like($help, qr/normal\s+- human-friendly summary \(default\)\./, 'help explains normal mode');
like($help, qr/puzzle\s+- render the input puzzle as-is without solving\./, 'help explains puzzle mode');
like($help, qr/explain\s+- show successful logical deductions\./, 'help explains explain mode');
like($help, qr/trace\s+- show solver decision flow, including unsuccessful strategy attempts\./,
    'help explains trace mode');
like($help, qr/debug\s+- show internal implementation details\./, 'help explains debug mode');
like($help, qr/--color MODE/, 'help documents color mode');
like($help, qr/--color-theme THEME/, 'help documents color theme');

my $themes = qx{$^X -Ilib bin/sudoku.pl --list-color-themes 2>&1};
is($? >> 8, 0, '--list-color-themes exits successfully');
like($themes, qr/^Available color themes/m, 'theme discovery has heading');
like($themes, qr/^    subtle \(default\)$/m, 'subtle is listed as default');
like($themes, qr/^    bright$/m, 'bright is listed');
like($themes, qr/^    greyscale$/m, 'greyscale is listed');

done_testing();
