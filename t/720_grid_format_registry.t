#!/usr/bin/env perl

use strict;
use warnings;

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

my $renderer = Sudoku::Render::Text->new;
my $grid = Local::Grid->new(1, (0) x 80);

is_deeply(
    [ $renderer->available_grid_formats ],
    [ qw(pretty compact markdown html svg png pdf puzzle-line grid-line solution-line candidates candidate-list candidate-line candidate-json) ],
    'available_grid_formats returns formats in discovery order',
);

is($renderer->default_grid_format, 'pretty', 'pretty is the default grid format');
ok($renderer->supports_grid_format('pretty'), 'pretty format is supported');
ok($renderer->supports_grid_format('compact'), 'compact format is supported');
ok($renderer->supports_grid_format('puzzle-line'), 'puzzle-line format is supported');
ok($renderer->supports_grid_format('grid-line'), 'grid-line format is supported');
ok($renderer->supports_grid_format('solution-line'), 'solution-line format is supported');
ok($renderer->supports_grid_format('candidates'), 'candidates format is supported');
ok($renderer->supports_grid_format('candidate-list'), 'candidate-list format is supported');
ok($renderer->supports_grid_format('candidate-line'), 'candidate-line format is supported');
ok($renderer->supports_grid_format('candidate-json'), 'candidate-json format is supported');
ok(!$renderer->supports_grid_format('json'), 'unknown format is not supported');
ok(!$renderer->supports_grid_format(undef), 'undefined format is not supported');

is(
    $renderer->render_grid($grid),
    $renderer->pretty_grid($grid),
    'render_grid uses the default pretty format',
);

is(
    $renderer->render_grid($grid, format => 'pretty'),
    $renderer->pretty_grid($grid),
    'render_grid dispatches the pretty format',
);

is(
    $renderer->render_grid(
        $grid,
        format               => 'compact',
        empty_cell_character => '_',
    ),
    "1________\n" . ("_________\n" x 8),
    'render_grid forwards format-specific options to compact_grid',
);

my $error = q{};
eval { $renderer->render_grid($grid, format => 'json') };
$error = $@;
like(
    $error,
    qr/Unknown grid format 'json'; available formats: pretty, compact, markdown, html, svg, png, pdf, puzzle-line, grid-line, solution-line, candidates, candidate-list, candidate-line/,
    'render_grid reports an unknown format and lists available formats',
);

done_testing;
