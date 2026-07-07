#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Test qw(capture_stdout);

my $grid = Grid->new;
$grid->load_from_string('1' . ('.' x 80));

my $out = capture_stdout { $grid->out };
my @out_lines = split /\n/, $out;
is(scalar @out_lines, 9, 'out prints nine rows');
like($out_lines[0], qr/^\s+1\s+0\s+0/, 'out prints the first row values');

my $pretty = capture_stdout { $grid->pretty_print };
like($pretty, qr/^\s+1\s+2\s+3/m, 'pretty_print includes column headers');
like($pretty, qr/ 1 \| 1 '   '   \|/m, 'pretty_print includes first row and given value');
like($pretty, qr/\+---\+---\+---\+---\+---\+---\+---\+---\+---\+/, 'pretty_print includes grid borders');

my $status = capture_stdout { $grid->status };
like($status, qr/Showing status of all cells:/, 'status prints a heading');
like($status, qr/\( 1, 1, 1 \) Given:\s+1/, 'status reports given cells');
like($status, qr/\( 1, 2, 1 \) \d left ->/, 'status reports unsolved cells');

my $multi_column_status = capture_stdout { $grid->multi_column_status };
like($multi_column_status, qr/Showing status of all cells:/, 'multi_column_status prints a heading');
like($multi_column_status, qr/\( 1, 1, 1 \) Given:\s+1/, 'multi_column_status reports given cells');
like($multi_column_status, qr/\( 1, 2, 1 \) \d left ->/, 'multi_column_status reports unsolved cells');

my $big_print = capture_stdout { $grid->big_print };
like($big_print, qr/^\s+1\s+2\s+3\s+4\s+5\s+6\s+7\s+8\s+9/m, 'big_print includes column headers');
like($big_print, qr/\+-------\+-------\+-------\+/, 'big_print includes wide grid borders');
like($big_print, qr/  1 \|\s+1\s+'/, 'big_print includes first row and given value');

done_testing();
