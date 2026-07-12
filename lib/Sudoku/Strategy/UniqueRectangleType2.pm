package Sudoku::Strategy::UniqueRectangleType2;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Uniqueness qw(
    candidate_values
    candidate_key
    cell_label
    common_peer_cells
    rectangle_cells
    rectangle_uses_two_boxes
);

sub name {
    return 'Unique Rectangle Type 2';
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
                        $grid,
                        $row_a,
                        $row_b,
                        $column_a,
                        $column_b,
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
                        next unless $roof[0]->possibilities->[0] == 3;
                        next unless $roof[1]->possibilities->[0] == 3;

                        my @pair = split /,/, $pair_key;
                        my @extra_a = _extras($roof[0], @pair);
                        my @extra_b = _extras($roof[1], @pair);
                        next unless @extra_a == 1 && @extra_b == 1;
                        next unless $extra_a[0] == $extra_b[0];

                        my $extra = $extra_a[0];
                        my $pattern = join q{, }, map { cell_label($_) } @cells;

                        for my $target (common_peer_cells($grid, @roof)) {
                            next unless $target->possibilities->[$extra];

                            my $key = join q{:}, $target->row, $target->column, $extra;
                            next if $seen{$key}++;

                            push @deductions, Sudoku::Deduction->new(
                                strategy    => $self->name,
                                action      => 'remove_candidate',
                                cell        => $target,
                                value       => $extra,
                                cells       => \@cells,
                                reason      => sprintf(
                                    '%s and %s are the roof cells of a Unique '
                                    . 'Rectangle {%s} and both contain extra candidate %d. '
                                    . 'At least one roof cell must contain %d to avoid a '
                                    . 'deadly rectangle. Because %s sees both roof cells, '
                                    . 'it cannot contain %d.',
                                    cell_label($roof[0]),
                                    cell_label($roof[1]),
                                    $pair_key,
                                    $extra,
                                    $extra,
                                    cell_label($target),
                                    $extra,
                                ),
                                explanation => sprintf(
                                    'Remove candidate %d from %s. Rectangle cells: %s.',
                                    $extra,
                                    cell_label($target),
                                    $pattern,
                                ),
                            );
                        }
                    }
                }
            }
        }
    }

    return @deductions;
}

sub _share_row_or_column {
    my ($left, $right) = @_;

    return 1 if $left->row == $right->row;
    return 1 if $left->column == $right->column;

    return 0;
}

sub _extras {
    my ($cell, @pair) = @_;

    my %pair = map { $_ => 1 } @pair;
    return grep { !$pair{$_} } candidate_values($cell);
}

1;
