package Sudoku::Uniqueness;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    candidate_values
    candidate_key
    cell_label
    common_peer_cells
    rectangle_cells
    rectangle_uses_two_boxes
);

sub candidate_values {
    my ($cell) = @_;

    return grep { $cell->possibilities->[$_] } 1 .. 9;
}

sub candidate_key {
    my ($cell) = @_;

    return join q{,}, candidate_values($cell);
}

sub cell_label {
    my ($cell) = @_;

    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

sub common_peer_cells {
    my ($grid, @pattern_cells) = @_;

    my %pattern = map { _cell_key($_) => 1 } @pattern_cells;

    return grep {
           !$_->value
        && !$pattern{ _cell_key($_) }
        && _sees_all($_, @pattern_cells)
    } @{ $grid->cells };
}

sub rectangle_cells {
    my ($grid, $row_a, $row_b, $column_a, $column_b) = @_;

    return (
        $grid->cell_from_row_column($row_a, $column_a),
        $grid->cell_from_row_column($row_a, $column_b),
        $grid->cell_from_row_column($row_b, $column_a),
        $grid->cell_from_row_column($row_b, $column_b),
    );
}

sub rectangle_uses_two_boxes {
    my (@cells) = @_;

    my %boxes = map { ( $_->box , 1 ) } @cells;
    return scalar(keys %boxes) == 2;
}

sub _sees_all {
    my ($target, @cells) = @_;

    for my $cell (@cells) {
        return 0 unless _cells_see_each_other($target, $cell);
    }

    return 1;
}

sub _cells_see_each_other {
    my ($left, $right) = @_;

    return 0 if $left == $right;
    return 1 if $left->row == $right->row;
    return 1 if $left->column == $right->column;
    return 1 if $left->box == $right->box;

    return 0;
}

sub _cell_key {
    my ($cell) = @_;

    return join q{:}, $cell->row, $cell->column;
}

1;
