package Sudoku::Strategy::TwoStringKite;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);

sub name {
    return 'Two-String Kite';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $value (1 .. 9) {
        my @row_links    = _strong_links($grid, $value, 'row');
        my @column_links = _strong_links($grid, $value, 'column');

        for my $row_link (@row_links) {
            for my $column_link (@column_links) {
                for my $row_connector_index (0, 1) {
                    for my $column_connector_index (0, 1) {
                        my $row_connector = $row_link->{cells}[$row_connector_index];
                        my $column_connector
                            = $column_link->{cells}[$column_connector_index];

                        next if $row_connector == $column_connector;
                        next unless $row_connector->box == $column_connector->box;

                        # The joining weak link must be a box link, rather than
                        # another row or column link.
                        next if $row_connector->row == $column_connector->row;
                        next if $row_connector->column == $column_connector->column;

                        my $row_remote
                            = $row_link->{cells}[1 - $row_connector_index];
                        my $column_remote
                            = $column_link->{cells}[1 - $column_connector_index];

                        my @pattern_cells = (
                            $row_remote,
                            $row_connector,
                            $column_connector,
                            $column_remote,
                        );
                        my %pattern_cell = map {
                            ( join(q{:}, $_->row, $_->column) => 1 )
                        } @pattern_cells;

                        for my $target (@{ $grid->cells }) {
                            next if $target->value;
                            next unless $target->possibilities->[$value];
                            next if $pattern_cell{
                                join(q{:}, $target->row, $target->column)
                            };
                            next unless _cells_see_each_other($target, $row_remote);
                            next unless _cells_see_each_other($target, $column_remote);

                            my $key = join q{:},
                                $target->row, $target->column, $value;
                            next if $seen{$key}++;

                            push @deductions, Sudoku::Deduction->new(
                                strategy => $self->name,
                                action   => 'remove_candidate',
                                cell     => $target,
                                value    => $value,
                                cells    => [ @pattern_cells ],
                                reason   => sprintf(
                                    'Candidate %d forms a Two-String Kite. '
                                    . '%s-%s is a strong link in row %d, '
                                    . '%s-%s is a strong link in column %d, '
                                    . 'and the connector cells %s and %s '
                                    . 'share box %d. Therefore at least one '
                                    . 'remote endpoint, %s or %s, must contain '
                                    . '%d, so %s cannot contain %d because it '
                                    . 'sees both remote endpoints.',
                                    $value,
                                    cell_label($row_remote),
                                    cell_label($row_connector),
                                    $row_connector->row + 1,
                                    cell_label($column_connector),
                                    cell_label($column_remote),
                                    $column_connector->column + 1,
                                    cell_label($row_connector),
                                    cell_label($column_connector),
                                    $row_connector->box + 1,
                                    cell_label($row_remote),
                                    cell_label($column_remote),
                                    $value,
                                    cell_label($target),
                                    $value,
                                ),
                                explanation => sprintf(
                                    'Remove candidate %d from %s. Two-String '
                                    . 'Kite remote endpoints: %s and %s.',
                                    $value,
                                    cell_label($target),
                                    cell_label($row_remote),
                                    cell_label($column_remote),
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

sub _strong_links {
    my ( $grid, $value, $orientation ) = @_;

    my @links;

    for my $base_index (0 .. 8) {
        my @cells;

        for my $cover_index (0 .. 8) {
            my $cell = $orientation eq 'row'
                ? $grid->cell_from_row_column($base_index, $cover_index)
                : $grid->cell_from_row_column($cover_index, $base_index);

            next if $cell->value;
            push @cells, $cell if $cell->possibilities->[$value];
        }

        next unless @cells == 2;

        push @links, {
            base_index => $base_index,
            cells      => \@cells,
        };
    }

    return @links;
}

sub _cells_see_each_other {
    my ( $first, $second ) = @_;

    return 1 if $first->row == $second->row;
    return 1 if $first->column == $second->column;
    return 1 if $first->box == $second->box;

    return 0;
}

1;
