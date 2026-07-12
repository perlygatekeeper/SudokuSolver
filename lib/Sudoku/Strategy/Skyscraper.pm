package Sudoku::Strategy::Skyscraper;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);

sub name {
    return 'Skyscraper';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $value (1 .. 9) {
        for my $orientation (qw(row column)) {
            my @links = _strong_links($grid, $value, $orientation);
            next if @links < 2;

            for my $first_index (0 .. $#links - 1) {
                for my $second_index ($first_index + 1 .. $#links) {
                    my $first  = $links[$first_index];
                    my $second = $links[$second_index];
                    my @shared = grep {
                        $_ == $second->{cover_indices}[0]
                            || $_ == $second->{cover_indices}[1]
                    } @{ $first->{cover_indices} };

                    next unless @shared == 1;

                    my $shared_cover = $shared[0];
                    my ($first_roof) = grep { $_ != $shared_cover }
                        @{ $first->{cover_indices} };
                    my ($second_roof) = grep { $_ != $shared_cover }
                        @{ $second->{cover_indices} };

                    next if $first_roof == $second_roof;

                    my $first_base = $first->{base_index};
                    my $second_base = $second->{base_index};
                    my $first_floor = _cell(
                        $grid, $orientation, $first_base, $shared_cover,
                    );
                    my $second_floor = _cell(
                        $grid, $orientation, $second_base, $shared_cover,
                    );
                    my $first_roof_cell = _cell(
                        $grid, $orientation, $first_base, $first_roof,
                    );
                    my $second_roof_cell = _cell(
                        $grid, $orientation, $second_base, $second_roof,
                    );
                    my @pattern_cells = (
                        $first_floor,
                        $first_roof_cell,
                        $second_floor,
                        $second_roof_cell,
                    );
                    my %pattern_cell = map {
                        ( join(q{:}, $_->row, $_->column) => 1 )
                    } @pattern_cells;

                    for my $target (@{ $grid->cells }) {
                        next if $target->value;
                        next unless $target->possibilities->[$value];
                        next if $pattern_cell{ join(q{:}, $target->row, $target->column) };
                        next unless _cells_see_each_other($target, $first_roof_cell);
                        next unless _cells_see_each_other($target, $second_roof_cell);

                        my $key = join q{:}, $target->row, $target->column, $value;
                        next if $seen{$key}++;

                        push @deductions, Sudoku::Deduction->new(
                            strategy => $self->name,
                            action   => 'remove_candidate',
                            cell     => $target,
                            value    => $value,
                            cells    => [ @pattern_cells ],
                            reason   => sprintf(
                                'Candidate %d forms a %s-based Skyscraper: '
                                . '%s-%s and %s-%s are strong links, while '
                                . '%s and %s share the same %s. At least one '
                                . 'roof, %s or %s, must contain %d, so %s '
                                . 'cannot contain %d because it sees both roofs.',
                                $value,
                                $orientation,
                                cell_label($first_floor),
                                cell_label($first_roof_cell),
                                cell_label($second_floor),
                                cell_label($second_roof_cell),
                                cell_label($first_floor),
                                cell_label($second_floor),
                                $orientation eq 'row' ? 'column' : 'row',
                                cell_label($first_roof_cell),
                                cell_label($second_roof_cell),
                                $value,
                                cell_label($target),
                                $value,
                            ),
                            explanation => sprintf(
                                'Remove candidate %d from %s. Skyscraper roofs: %s and %s.',
                                $value,
                                cell_label($target),
                                cell_label($first_roof_cell),
                                cell_label($second_roof_cell),
                            ),
                        );
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
        my @cover_indices;

        for my $cover_index (0 .. 8) {
            my $cell = _cell($grid, $orientation, $base_index, $cover_index);
            next if $cell->value;
            push @cover_indices, $cover_index
                if $cell->possibilities->[$value];
        }

        next unless @cover_indices == 2;

        push @links, {
            base_index    => $base_index,
            cover_indices => \@cover_indices,
        };
    }

    return @links;
}

sub _cell {
    my ( $grid, $orientation, $base_index, $cover_index ) = @_;

    return $orientation eq 'row'
        ? $grid->cell_from_row_column($base_index, $cover_index)
        : $grid->cell_from_row_column($cover_index, $base_index);
}

sub _cells_see_each_other {
    my ( $first, $second ) = @_;

    return 1 if $first->row == $second->row;
    return 1 if $first->column == $second->column;
    return 1 if $first->box == $second->box;

    return 0;
}

1;
