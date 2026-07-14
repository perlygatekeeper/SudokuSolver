#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON::PP qw(decode_json);

use lib '.';
use Sudoku::Render::Text;

{
    package Local::CandidateJSONCell;
    sub new { my ($class, %args) = @_; return bless \%args, $class }
    sub value { return $_[0]->{value} }
    sub given { return $_[0]->{given} }
    sub possibilities { return $_[0]->{possibilities} }
}

{
    package Local::CandidateJSONGrid;
    sub new { my ($class, @cells) = @_; return bless { cells => \@cells }, $class }
    sub cells { return $_[0]->{cells} }
}

sub possibilities {
    my (@digits) = @_;
    my @possible = (0) x 10;
    $possible[$_] = 1 for @digits;
    return \@possible;
}

my @cells = (
    Local::CandidateJSONCell->new(value => 5, given => 1, possibilities => possibilities()),
    Local::CandidateJSONCell->new(value => 3, given => 0, possibilities => possibilities()),
    Local::CandidateJSONCell->new(value => 0, given => 0, possibilities => possibilities(1, 2, 4)),
    Local::CandidateJSONCell->new(value => 0, given => 0, possibilities => possibilities()),
    map {
        Local::CandidateJSONCell->new(
            value => 0, given => 0, possibilities => possibilities(1 .. 9),
        )
    } 5 .. 81,
);

my $grid = Local::CandidateJSONGrid->new(@cells);
my $renderer = Sudoku::Render::Text->new;
my $json = $renderer->candidate_json($grid);
my $data = decode_json($json);

is($data->{format}, 'SudokuSolver candidate-state', 'format identifies candidate-state document');
is($data->{version}, 1, 'schema version is one');
is(length($data->{puzzle}), 81, 'original puzzle contains 81 cells');
is(substr($data->{puzzle}, 0, 4), '5000', 'puzzle contains givens only');
is(length($data->{current_grid}), 81, 'current grid contains 81 cells');
is(substr($data->{current_grid}, 0, 4), '5300', 'current grid includes solved non-given cells');
is(ref($data->{candidates}), 'ARRAY', 'candidates is an array');
is(scalar @{ $data->{candidates} }, 81, 'candidate array contains exactly 81 fields');
is_deeply([ @{ $data->{candidates} }[0 .. 3] ], [ qw(5 3 124 -) ], 'candidate fields preserve state');
is(substr($json, -1), "\n", 'JSON document ends with a newline');
ok($renderer->supports_grid_format('candidate-json'), 'candidate-json is registered');
is($renderer->render_grid($grid, format => 'candidate-json'), $json, 'dispatcher renders candidate-json');

my $error = q{};
eval { $renderer->candidate_json() };
$error = $@;
like($error, qr/candidate_json requires a grid object/, 'grid is required');

my $short_grid = Local::CandidateJSONGrid->new(@cells[0 .. 79]);
$error = q{};
eval { $renderer->candidate_json($short_grid) };
$error = $@;
like($error, qr/requires exactly 81 cells/, 'exactly 81 cells are required');

done_testing;
