#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib '.';

use Sudoku::Render::Text;

{
    package Local::CandidateCell;

    sub new {
        my ($class, %args) = @_;
        return bless \%args, $class;
    }

    sub value {
        my ($self) = @_;
        return $self->{value};
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
    my @possible = (0) x 10;
    $possible[$_] = 1 for @digits;
    return \@possible;
}

my @cells = (
    Local::CandidateCell->new(value => 5, possibilities => possibilities()),
    Local::CandidateCell->new(value => 0, possibilities => possibilities(1, 2, 4)),
    Local::CandidateCell->new(value => 0, possibilities => possibilities()),
    map {
        Local::CandidateCell->new(
            value         => 0,
            possibilities => possibilities(1 .. 9),
        )
    } 4 .. 81,
);

my $grid = Local::CandidateGrid->new(@cells);
my $renderer = Sudoku::Render::Text->new;
my $text = $renderer->candidate_line($grid);

my @fields = split /,/, $text;
$fields[-1] =~ s/\n\z//;

is(scalar @fields, 81, 'candidate line contains exactly 81 fields');
is($fields[0], '5', 'solved cell contains its value');
is($fields[1], '124', 'unsolved cell contains sorted remaining candidates');
is($fields[2], '-', 'cell with no candidates uses contradiction marker');
is($fields[80], '123456789', 'last field preserves all candidates');
is(substr($text, -1), "\n", 'candidate line ends with a newline');
is(($text =~ tr/,/,/), 80, 'candidate line contains exactly 80 commas');

ok(
    $renderer->supports_grid_format('candidate-line'),
    'candidate-line is registered as a grid format',
);
is(
    $renderer->render_grid($grid, format => 'candidate-line'),
    $text,
    'render_grid dispatches candidate-line',
);

my $error = q{};
eval { $renderer->candidate_line() };
$error = $@;
like($error, qr/candidate_line requires a grid object/, 'grid is required');

my $short_grid = Local::CandidateGrid->new(@cells[0 .. 79]);
$error = q{};
eval { $renderer->candidate_line($short_grid) };
$error = $@;
like($error, qr/requires exactly 81 cells/, 'exactly 81 cells are required');

done_testing;
