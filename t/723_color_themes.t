#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Sudoku::Render::GridBuilder;
use Sudoku::Render::Text;
use Sudoku::Render::Theme;

is_deeply(
    [Sudoku::Render::Theme->names],
    [qw(subtle bright greyscale)],
    'theme registry has stable order',
);

for my $name (Sudoku::Render::Theme->names) {
    my $theme = Sudoku::Render::Theme->new(name => $name);
    is($theme->name, $name, "$name theme loads");
    like($theme->style('heading', 'Heading'), qr/\A\e\[[0-9;]+mHeading\e\[0m\z/,
        "$name theme applies ANSI styling");
}

my $plain = Sudoku::Render::Text->new(
    color       => 'never',
    color_theme => 'bright',
);
$plain->color_enabled(0);
is($plain->style('success', 'Solved'), 'Solved', 'disabled color returns plain text');

my $colored = Sudoku::Render::Text->new(
    color       => 'always',
    color_theme => 'bright',
);
$colored->color_enabled(1);
like($colored->style('success', 'Solved'), qr/\e\[[0-9;]+mSolved\e\[0m/,
    'enabled color applies selected theme');

my $builder = Sudoku::Render::GridBuilder->new;
my $styled = "\e[1;96m5\e[0m";
is(
    $builder->row(cells => [$styled, '6'], width => 3),
    "| \e[1;96m5\e[0m ' 6 |",
    'grid builder aligns cells by visible width rather than ANSI byte length',
);

done_testing();
