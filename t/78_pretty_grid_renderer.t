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

my $grid = Local::Grid->new(1, (0) x 80);

my $ascii = Sudoku::Render::Text->new;
my $text = $ascii->pretty_grid($grid);

my $expected = <<'GRID';
     1   2   3   4   5   6   7   8   9  
   +---+---+---+---+---+---+---+---+---+
 1 | 1 '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 2 |   '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 3 |   '   '   |   '   '   |   '   '   |
   +---+---+---+---+---+---+---+---+---+
 4 |   '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 5 |   '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 6 |   '   '   |   '   '   |   '   '   |
   +---+---+---+---+---+---+---+---+---+
 7 |   '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 8 |   '   '   |   '   '   |   '   '   |
   + - + - + - + - + - + - + - + - + - +
 9 |   '   '   |   '   '   |   '   '   |
   +---+---+---+---+---+---+---+---+---+
GRID

is($text, $expected, 'ASCII pretty_grid preserves the existing pretty_print format exactly');

my $light = Sudoku::Render::Text->new(
    character_set => 'UNICODE_LIGHT',
)->pretty_grid($grid);

like($light, qr/^   ┌───┬───┬───┬───┬───┬───┬───┬───┬───┐$/m,
    'light Unicode pretty grid uses light top-border characters');
like($light, qr/^ 1 │ 1 │   │   │   │   │   │   │   │   │$/m,
    'light Unicode pretty grid renders the value row');
like($light, qr/^   └───┴───┴───┴───┴───┴───┴───┴───┴───┘$/m,
    'light Unicode pretty grid uses light bottom-border characters');

my $double = Sudoku::Render::Text->new(
    character_set => 'UNICODE_DOUBLE',
)->pretty_grid($grid);
like($double, qr/^   ╔═══╦═══╦═══╦═══╦═══╦═══╦═══╦═══╦═══╗$/m,
    'double Unicode pretty grid uses double-line characters');

my $heavy = Sudoku::Render::Text->new(
    character_set => 'UNICODE_HEAVY',
)->pretty_grid($grid);
like($heavy, qr/^   ┏━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┳━━━┓$/m,
    'heavy Unicode pretty grid uses heavy characters');

my $error = q{};
eval { $ascii->pretty_grid(undef) };
$error = $@;
like($error, qr/requires a grid object/, 'pretty_grid rejects a missing grid');

done_testing;
