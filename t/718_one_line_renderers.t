#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Sudoku::Render::Text;

{
    package Local::LineCell;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    sub value { return $_[0]{value}; }
    sub given { return $_[0]{given}; }
}

{
    package Local::LineGrid;

    sub new {
        my ($class, @cells) = @_;
        return bless { cells => \@cells }, $class;
    }

    sub cells { return $_[0]{cells}; }
}

my @cells = (
    Local::LineCell->new(value => 5, given => 1),
    Local::LineCell->new(value => 3, given => 0),
    Local::LineCell->new(value => 0, given => 0),
    map { Local::LineCell->new(value => 0, given => 0) } 4 .. 81,
);
my $grid = Local::LineGrid->new(@cells);
my $renderer = Sudoku::Render::Text->new;

is(
    $renderer->puzzle_line($grid),
    '5' . ('0' x 80) . "\n",
    'puzzle_line emits givens only',
);

is(
    $renderer->grid_line($grid),
    '530' . ('0' x 78) . "\n",
    'grid_line emits current values',
);

is(
    $renderer->puzzle_line($grid, empty_cell_character => '.'),
    '5' . ('.' x 80) . "\n",
    'puzzle_line accepts a custom empty-cell character',
);

is(
    $renderer->grid_line($grid, empty_cell_character => '_'),
    '53_' . ('_' x 78) . "\n",
    'grid_line accepts a custom empty-cell character',
);

my @solved_cells = map {
    Local::LineCell->new(value => (($_ - 1) % 9) + 1, given => $_ <= 9)
} 1 .. 81;
my $solved_grid = Local::LineGrid->new(@solved_cells);
my $solution = join(q{}, map { (($_ - 1) % 9) + 1 } 1 .. 81) . "\n";

is($renderer->solution_line($solved_grid), $solution, 'solution_line emits 81 solved values');
is(
    $renderer->render_grid($grid, format => 'puzzle-line'),
    $renderer->puzzle_line($grid),
    'dispatcher renders puzzle-line',
);
is(
    $renderer->render_grid($grid, format => 'grid-line'),
    $renderer->grid_line($grid),
    'dispatcher renders grid-line',
);
is(
    $renderer->render_grid($solved_grid, format => 'solution-line'),
    $solution,
    'dispatcher renders solution-line',
);

my $error = q{};
eval { $renderer->solution_line($grid) };
$error = $@;
like($error, qr/requires a solved grid/, 'solution_line rejects an unsolved grid');

eval { $renderer->grid_line($grid, empty_cell_character => '..') };
$error = $@;
like($error, qr/exactly one character/, 'one-line formats validate the empty-cell character');

done_testing;
