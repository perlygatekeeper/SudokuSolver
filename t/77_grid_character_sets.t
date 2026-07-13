#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';

use Sudoku::Render::GridCharacters;
use Sudoku::Render::Text;

ok(
    Sudoku::Render::GridCharacters->validate_all,
    'all built-in grid character sets validate',
);

is_deeply(
    [ Sudoku::Render::GridCharacters->names ],
    [ qw(ASCII UNICODE_DOUBLE UNICODE_HEAVY UNICODE_LIGHT) ],
    'character sets are discoverable',
);

my $ascii = Sudoku::Render::GridCharacters->character_set('ASCII');
is($ascii->{horizontal}, '-', 'ASCII horizontal character');
is($ascii->{vertical}, '|', 'ASCII major vertical character');
is($ascii->{vertical_minor}, q{'}, 'ASCII minor vertical character');
is($ascii->{cross}, '+', 'ASCII intersections use plus signs');

my $light = Sudoku::Render::GridCharacters->character_set('UNICODE_LIGHT');
is($light->{corner_down_right}, '┌', 'light Unicode top-left corner');
is($light->{cross}, '┼', 'light Unicode cross');

my $double = Sudoku::Render::GridCharacters->character_set('UNICODE_DOUBLE');
is($double->{horizontal}, '═', 'double Unicode horizontal');
is($double->{tee_down}, '╦', 'double Unicode top-edge tee');

my $heavy = Sudoku::Render::GridCharacters->character_set('UNICODE_HEAVY');
is($heavy->{vertical}, '┃', 'heavy Unicode vertical');
is($heavy->{corner_up_left}, '┛', 'heavy Unicode bottom-right corner');

is(
    Sudoku::Render::GridCharacters->canonical_name('UNICODE_NORMAL'),
    'UNICODE_LIGHT',
    'UNICODE_NORMAL is an alias for UNICODE_LIGHT',
);

is(
    Sudoku::Render::GridCharacters->canonical_name('UNICODE_BOLD'),
    'UNICODE_HEAVY',
    'UNICODE_BOLD is an alias for UNICODE_HEAVY',
);

my $renderer = Sudoku::Render::Text->new;
is($renderer->character_set, 'ASCII', 'text renderer defaults to ASCII');
is($renderer->grid_characters->{tee_left}, '+', 'renderer exposes selected characters');

my $unicode_renderer = Sudoku::Render::Text->new(
    character_set => 'UNICODE_DOUBLE',
);
is(
    $unicode_renderer->character_set,
    'UNICODE_DOUBLE',
    'renderer accepts a Unicode character set',
);
is(
    $unicode_renderer->grid_characters->{corner_down_left},
    '╗',
    'renderer exposes the selected Unicode characters',
);

my $copy = $unicode_renderer->grid_characters;
$copy->{horizontal} = 'x';
is(
    $unicode_renderer->grid_characters->{horizontal},
    '═',
    'callers cannot mutate the renderer character set',
);

my $error = q{};
eval { Sudoku::Render::Text->new(character_set => 'NOT_A_STYLE') };
$error = $@;
like($error, qr/Unknown grid character set 'NOT_A_STYLE'/, 'unknown sets are rejected');

done_testing;
