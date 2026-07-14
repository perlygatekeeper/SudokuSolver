#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';

use Sudoku::Render::Text;

{
    package Local::Cell;

    sub new {
        my ($class, $value) = @_;
        return bless { value => $value }, $class;
    }

    sub value {
        my ($self) = @_;
        return $self->{value};
    }
}

{
    package Local::Grid;

    sub new {
        my ($class, @values) = @_;
        return bless {
            cells => [ map { Local::Cell->new($_) } @values ],
        }, $class;
    }

    sub cells {
        my ($self) = @_;
        return $self->{cells};
    }
}

my @values = map { $_ eq '.' ? 0 : $_ } split //,
    '53..7....' .
    '6..195...' .
    '.98....6.' .
    '8...6...3' .
    '4..8.3..1' .
    '7...2...6' .
    '.6....28.' .
    '...419..5' .
    '....8..79';

my $grid = Local::Grid->new(@values);
my $renderer = Sudoku::Render::Text->new;

my $expected_dots = <<'GRID';
53..7....
6..195...
.98....6.
8...6...3
4..8.3..1
7...2...6
.6....28.
...419..5
....8..79
GRID

is(
    $renderer->compact_grid($grid),
    $expected_dots,
    'compact_grid defaults to periods for empty cells',
);

(my $expected_underscores = $expected_dots) =~ tr/./_/;
is(
    $renderer->compact_grid(
        $grid,
        empty_cell_character => '_',
    ),
    $expected_underscores,
    'compact_grid accepts underscores for empty cells',
);

(my $expected_spaces = $expected_dots) =~ tr/./ /;
is(
    $renderer->compact_grid(
        $grid,
        empty_cell_character => ' ',
    ),
    $expected_spaces,
    'compact_grid accepts spaces for empty cells',
);

(my $expected_zeroes = $expected_dots) =~ tr/./0/;
is(
    $renderer->compact_grid(
        $grid,
        empty_cell_character => '0',
    ),
    $expected_zeroes,
    'compact_grid accepts zeroes for empty cells',
);

for my $invalid (q{}, '..', undef) {
    my $error = q{};
    eval {
        $renderer->compact_grid(
            $grid,
            empty_cell_character => $invalid,
        );
    };
    $error = $@;

    like(
        $error,
        qr/empty_cell_character must be exactly one character/,
        'compact_grid rejects an invalid empty-cell character',
    );
}

{
    my $error = q{};
    eval { $renderer->compact_grid(undef) };
    $error = $@;
    like($error, qr/requires a grid object/, 'compact_grid rejects a missing grid');
}

{
    my $short_grid = Local::Grid->new((0) x 80);
    my $error = q{};
    eval { $renderer->compact_grid($short_grid) };
    $error = $@;
    like($error, qr/requires exactly 81 cells/, 'compact_grid requires 81 cells');
}

done_testing;
