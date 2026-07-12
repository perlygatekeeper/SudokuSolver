package Sudoku::Wing;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
    candidate_values
    cells_see_each_other
    common_peer_cells
    combinations
    cell_label
);

sub candidate_values {
    my ($cell) = @_;

    return grep { $cell->possibilities->[$_] } 1 .. 9;
}

sub cells_see_each_other {
    my ($left, $right) = @_;

    return 0 if $left == $right;
    return 1 if $left->row == $right->row;
    return 1 if $left->column == $right->column;
    return 1 if $left->box == $right->box;

    return 0;
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

sub combinations {
    my ($items, $size) = @_;

    my @combinations;
    _collect_combinations($items, $size, 0, [], \@combinations);

    return @combinations;
}

sub cell_label {
    my ($cell) = @_;

    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

sub _collect_combinations {
    my ($items, $size, $start, $chosen, $results) = @_;

    if (@{$chosen} == $size) {
        push @{$results}, [ @{$chosen} ];
        return;
    }

    my $remaining_needed = $size - @{$chosen};
    my $last_start = @{$items} - $remaining_needed;

    for my $index ($start .. $last_start) {
        push @{$chosen}, $items->[$index];
        _collect_combinations($items, $size, $index + 1, $chosen, $results);
        pop @{$chosen};
    }
}

sub _sees_all {
    my ($target, @cells) = @_;

    for my $cell (@cells) {
        return 0 unless cells_see_each_other($target, $cell);
    }

    return 1;
}

sub _cell_key {
    my ($cell) = @_;

    return join q{:}, $cell->row, $cell->column;
}

1;
