package Sudoku::Strategy::UniqueRectangleType4;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Uniqueness qw(
    candidate_key
    cell_label
    rectangle_cells
    rectangle_uses_two_boxes
);

sub name {
    return 'Unique Rectangle Type 4';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;
    my %seen;

    for my $row_a (0 .. 7) {
        for my $row_b ($row_a + 1 .. 8) {
            for my $column_a (0 .. 7) {
                for my $column_b ($column_a + 1 .. 8) {
                    my @cells = rectangle_cells(
                        $grid, $row_a, $row_b, $column_a, $column_b,
                    );

                    next if grep { $_->value } @cells;
                    next unless rectangle_uses_two_boxes(@cells);

                    my %pair_cells;
                    for my $cell (@cells) {
                        next unless $cell->possibilities->[0] == 2;
                        push @{ $pair_cells{ candidate_key($cell) } }, $cell;
                    }

                    for my $pair_key (keys %pair_cells) {
                        my @floor = @{ $pair_cells{$pair_key} };
                        next unless @floor == 2;
                        next unless _share_row_or_column(@floor);

                        my @roof = grep {
                            my $candidate = $_;
                            !grep { $_ == $candidate } @floor;
                        } @cells;
                        next unless @roof == 2;
                        next unless _share_row_or_column(@roof);
                        next unless $roof[0]->possibilities->[0] > 2;
                        next unless $roof[1]->possibilities->[0] > 2;

                        my @pair = split /,/, $pair_key;
                        next if grep { !_contains_all($_, @pair) } @roof;

                        my @unit = _shared_unit($grid, @roof);
                        my $pattern = join q{, }, map { cell_label($_) } @cells;

                        for my $strong (@pair) {
                            my @positions = grep {
                                !$_->value && $_->possibilities->[$strong]
                            } @unit;
                            next unless @positions == 2;
                            next unless _same_cells(\@positions, \@roof);

                            my ($remove) = grep { $_ != $strong } @pair;

                            for my $target (@roof) {
                                next unless $target->possibilities->[$remove];

                                my $key = join q{:},
                                    $target->row, $target->column, $remove;
                                next if $seen{$key}++;

                                push @deductions, Sudoku::Deduction->new(
                                    strategy => $self->name,
                                    action   => 'remove_candidate',
                                    cell     => $target,
                                    value    => 0 + $remove,
                                    cells    => \@cells,
                                    reason   => sprintf(
                                        '%s and %s are the roof cells of a Unique '
                                        . 'Rectangle {%s}. Candidate %d appears only in '
                                        . 'those two cells in their shared unit, so one '
                                        . 'roof must contain %d. To avoid a deadly '
                                        . 'rectangle, neither roof can contain the other '
                                        . 'rectangle candidate %d.',
                                        cell_label($roof[0]),
                                        cell_label($roof[1]),
                                        $pair_key,
                                        $strong,
                                        $strong,
                                        $remove,
                                    ),
                                    explanation => sprintf(
                                        'Remove candidate %d from %s. Rectangle cells: %s.',
                                        $remove, cell_label($target), $pattern,
                                    ),
                                );
                            }
                        }
                    }
                }
            }
        }
    }

    return @deductions;
}

sub _contains_all {
    my ($cell, @values) = @_;
    return !grep { !$cell->possibilities->[$_] } @values;
}

sub _share_row_or_column {
    my ($left, $right) = @_;
    return 1 if $left->row == $right->row;
    return 1 if $left->column == $right->column;
    return 0;
}

sub _shared_unit {
    my ($grid, $left, $right) = @_;
    return @{ $grid->rows->[ $left->row ] }
        if $left->row == $right->row;
    return @{ $grid->columns->[ $left->column ] };
}

sub _same_cells {
    my ($left, $right) = @_;
    my %left = map { (_cell_key($_) => 1) } @{$left};
    return !grep { !$left{ _cell_key($_) } } @{$right};
}

sub _cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

1;
