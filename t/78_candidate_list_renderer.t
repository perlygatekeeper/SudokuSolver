#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Sudoku::Render::Text;

{
    package Local::CandidateCell;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    sub value {
        my ($self) = @_;
        return $self->{value} // 0;
    }

    sub possibilities {
        my ($self) = @_;
        return $self->{possibilities};
    }
}

{
    package Local::CandidateGrid;

    sub new {
        my ($class, @cells) = @_;
        return bless { cells => \@cells }, $class;
    }

    sub cells {
        my ($self) = @_;
        return $self->{cells};
    }
}

sub possibilities {
    my (@digits) = @_;
    my @values = (0) x 10;
    $values[0] = scalar @digits;
    $values[$_] = $_ for @digits;
    return \@values;
}

my @cells = (
    Local::CandidateCell->new(value => 5),
    Local::CandidateCell->new(value => 3),
    Local::CandidateCell->new(possibilities => possibilities(1, 2, 4)),
    Local::CandidateCell->new(possibilities => possibilities(2, 6)),
    Local::CandidateCell->new(value => 7),
    Local::CandidateCell->new(possibilities => possibilities(2, 4, 6, 8)),
    Local::CandidateCell->new(possibilities => possibilities(1, 4, 8, 9)),
    Local::CandidateCell->new(possibilities => possibilities(1, 2, 4, 9)),
    Local::CandidateCell->new(possibilities => possibilities(2, 4, 8)),
);

push @cells, map {
    Local::CandidateCell->new(possibilities => possibilities(1 .. 9))
} 1 .. 71;

push @cells, Local::CandidateCell->new(possibilities => possibilities());

my $grid = Local::CandidateGrid->new(@cells);
my $renderer = Sudoku::Render::Text->new;
my $text = $renderer->candidate_list($grid);
my @lines = split /\n/, $text;

is(scalar @lines, 9, 'candidate list contains nine labeled rows');
is(
    $lines[0],
    'R1: 5 3 124 26 7 2468 1489 1249 248',
    'candidate list renders solved values and remaining candidates',
);
is(
    $lines[8],
    'R9: 123456789 123456789 123456789 123456789 123456789 123456789 123456789 123456789 -',
    'candidate list uses an explicit marker for a cell with no candidates',
);
is(substr($text, -1), "\n", 'candidate list ends with a newline');

ok(
    $renderer->supports_grid_format('candidate-list'),
    'candidate-list is registered as a grid format',
);
is(
    $renderer->render_grid($grid, format => 'candidate-list'),
    $text,
    'render_grid dispatches candidate-list',
);

my $error = q{};
eval { $renderer->candidate_list() };
$error = $@;
like($error, qr/candidate_list requires a grid object/, 'grid is required');

my $short_grid = Local::CandidateGrid->new(@cells[0 .. 79]);
$error = q{};
eval { $renderer->candidate_list($short_grid) };
$error = $@;
like($error, qr/requires exactly 81 cells/, 'exactly 81 cells are required');

done_testing;
