#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

use lib 'lib';

use Sudoku::Render::Text;

{
    package Local::CandidateCell;

    sub new {
        my ($class, %args) = @_;
        return bless {
            value         => $args{value} // 0,
            possibilities => $args{possibilities} // [ 0, (0) x 9 ],
        }, $class;
    }

    sub value         { return $_[0]->{value} }
    sub possibilities { return $_[0]->{possibilities} }
}

{
    package Local::CandidateGrid;

    sub new {
        my ($class, @cells) = @_;
        return bless { cells => \@cells }, $class;
    }

    sub cells { return $_[0]->{cells} }
}

my @all_candidates = (9, 1, 2, 3, 4, 5, 6, 7, 8, 9);
my @cells = (
    Local::CandidateCell->new(value => 5),
    Local::CandidateCell->new(possibilities => [ @all_candidates ]),
    map { Local::CandidateCell->new(possibilities => [ @all_candidates ]) } 3 .. 81,
);
my $grid = Local::CandidateGrid->new(@cells);

my $renderer = Sudoku::Render::Text->new;
my $text = $renderer->candidate_grid($grid);

my @lines = split /\n/, $text, -1;
is(scalar @lines, 40, 'candidate grid contains 39 display lines and a trailing newline');
is(length($lines[0]), 79, 'candidate grid preserves the legacy blank first line width');
is(length($lines[2]), 79, 'candidate grid preserves the legacy line width');
like($text, qr/^        1       2       3       4       5       6       7       8       9      $/m,
    'candidate grid includes column headings');
like($text, qr/^  1 \|   5   ' 4 5 6 '/m,
    'candidate grid centers solved values and renders candidate rows');
like($text, qr/^    \|       ' 1 2 3 '/m,
    'candidate grid renders top-row candidates');
like($text, qr/^    \|       ' 7 8 9 '/m,
    'candidate grid renders bottom-row candidates');

is(
    $renderer->render_grid($grid, format => 'candidates'),
    $text,
    'render_grid dispatches the candidates format',
);

my $light = Sudoku::Render::Text->new(
    character_set => 'UNICODE_LIGHT',
)->candidate_grid($grid);
like($light, qr/^    ┌───────┬───────┬/m,
    'light Unicode candidate grid uses light border characters');
like($light, qr/^  1 │   5   │ 4 5 6 │/m,
    'light Unicode candidate grid uses light vertical characters');

my $double = Sudoku::Render::Text->new(
    character_set => 'UNICODE_DOUBLE',
)->candidate_grid($grid);
like($double, qr/^    ╔═══════╦═══════╦/m,
    'double Unicode candidate grid uses double-line characters');

my $heavy = Sudoku::Render::Text->new(
    character_set => 'UNICODE_HEAVY',
)->candidate_grid($grid);
like($heavy, qr/^    ┏━━━━━━━┳━━━━━━━┳/m,
    'heavy Unicode candidate grid uses heavy characters');

my $error = q{};
eval { $renderer->candidate_grid(undef) };
$error = $@;
like($error, qr/requires a grid object/, 'candidate_grid rejects a missing grid');

my $short_grid = Local::CandidateGrid->new(@cells[0 .. 79]);
eval { $renderer->candidate_grid($short_grid) };
$error = $@;
like($error, qr/requires exactly 81 cells/, 'candidate_grid requires exactly 81 cells');

done_testing();
