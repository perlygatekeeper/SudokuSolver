package Sudoku::PatternSymmetry;

use strict;
use warnings;

use Exporter qw(import);

use Sudoku::CoordinateEncoding qw(validate_puzzle_string);

our @EXPORT_OK = qw(pattern_symmetries);

my @SYMMETRIES = (
    [ 'rotation-180'             => sub { 8 - $_[0], 8 - $_[1] } ],
    [ 'rotation-90'              => sub { $_[1],     8 - $_[0] } ],
    [ 'reflection-horizontal'    => sub { 8 - $_[0], $_[1]     } ],
    [ 'reflection-vertical'      => sub { $_[0],     8 - $_[1] } ],
    [ 'reflection-main-diagonal' => sub { $_[1],     $_[0]     } ],
    [ 'reflection-anti-diagonal' => sub { 8 - $_[1], 8 - $_[0] } ],
);

sub pattern_symmetries {
    my ($puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my @names;
    for my $spec (@SYMMETRIES) {
        my ($name, $transform) = @{$spec};
        push @names, $name if _preserves_clue_mask($puzzle, $transform);
    }

    return wantarray ? @names : \@names;
}

sub _preserves_clue_mask {
    my ($puzzle, $transform) = @_;

    for my $row (0 .. 8) {
        for my $column (0 .. 8) {
            my $source_has_clue = substr($puzzle, $row * 9 + $column, 1) ne '0';
            my ($target_row, $target_column) = $transform->($row, $column);
            my $target_has_clue =
                substr($puzzle, $target_row * 9 + $target_column, 1) ne '0';

            return 0 if $source_has_clue != $target_has_clue;
        }
    }

    return 1;
}

1;
