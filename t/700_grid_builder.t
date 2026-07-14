#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';

use Sudoku::Render::GridBuilder;
use Sudoku::Render::Text;

my $ascii = Sudoku::Render::GridBuilder->new;
is($ascii->character_set, 'ASCII', 'builder defaults to ASCII');

is(
    $ascii->horizontal_rule(
        left          => 'corner_down_right',
        junction      => 'tee_down',
        right         => 'corner_down_left',
        segments      => 3,
        segment_width => 3,
    ),
    '+---+---+---+',
    'builds a uniform ASCII top rule',
);

is(
    $ascii->horizontal_rule(
        segment_widths => [ 1, 2, 3 ],
    ),
    '+-+--+---+',
    'builds a rule with variable segment widths',
);

is(
    $ascii->row(
        cells      => [ 1, q{}, 3 ],
        width      => 3,
        separators => [ 'vertical_minor', 'vertical' ],
    ),
    q{| 1 '   | 3 |},
    'builds an ASCII row with major and minor separators',
);

is(
    $ascii->row(
        cells     => [ '12', '3' ],
        widths    => [ 3, 2 ],
        separator => 'vertical',
        align     => 'right',
    ),
    '| 12| 3|',
    'supports variable widths and right alignment',
);

my $light = Sudoku::Render::GridBuilder->new(
    character_set => 'UNICODE_LIGHT',
);
is(
    $light->horizontal_rule(
        left          => 'corner_down_right',
        junction      => 'tee_down',
        right         => 'corner_down_left',
        segments      => 2,
        segment_width => 3,
    ),
    '┌───┬───┐',
    'same rule construction works with light Unicode',
);

is(
    $light->row(
        cells     => [ 5, 7 ],
        width     => 3,
        separator => 'vertical_minor',
    ),
    '│ 5 │ 7 │',
    'same row construction works with light Unicode',
);

my $double = Sudoku::Render::GridBuilder->new(
    character_set => 'UNICODE_DOUBLE',
);
is(
    $double->horizontal_rule(
        left          => 'corner_down_right',
        junction      => 'tee_down',
        right         => 'corner_down_left',
        segments      => 2,
        segment_width => 2,
    ),
    '╔══╦══╗',
    'same rule construction works with double Unicode',
);

my $heavy = Sudoku::Render::GridBuilder->new(
    character_set => 'UNICODE_BOLD',
);
is($heavy->character_set, 'UNICODE_HEAVY', 'builder accepts character-set aliases');
is(
    $heavy->horizontal_rule(
        left          => 'corner_up_right',
        junction      => 'tee_up',
        right         => 'corner_up_left',
        segments      => 2,
        segment_width => 2,
    ),
    '┗━━┻━━┛',
    'same rule construction works with heavy Unicode',
);

my $renderer = Sudoku::Render::Text->new(
    character_set => 'UNICODE_DOUBLE',
);
my $renderer_builder = $renderer->grid_builder;
isa_ok($renderer_builder, 'Sudoku::Render::GridBuilder');
is(
    $renderer_builder->character_set,
    'UNICODE_DOUBLE',
    'renderer creates a builder using its selected character set',
);

my $characters = $ascii->characters;
$characters->{horizontal} = 'x';
is(
    $ascii->characters->{horizontal},
    '-',
    'callers cannot mutate builder characters',
);

my $error = q{};
eval {
    $ascii->row(
        cells => [ 'toolong' ],
        width => 3,
    );
};
$error = $@;
like($error, qr/wider than its configured width/, 'oversized cell values are rejected');

$error = q{};
eval {
    $ascii->horizontal_rule(
        left => 'not_a_component',
    );
};
$error = $@;
like($error, qr/Unknown grid character component/, 'unknown components are rejected');

done_testing;
