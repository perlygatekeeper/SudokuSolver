package Sudoku::Strategy::UniqueRectangleType3;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Uniqueness qw(
    candidate_values
    candidate_key
    cell_label
    rectangle_cells
    rectangle_uses_two_boxes
);

sub name {
    return 'Unique Rectangle Type 3';
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

                        my @pair = split /,/, $pair_key;
                        next if grep { !_contains_all($_, @pair) } @roof;
                        next unless grep { $_->possibilities->[0] > 2 } @roof;

                        my %extras;
                        $extras{$_} = 1 for map { _extras($_, @pair) } @roof;
                        my @extras = sort { $a <=> $b } keys %extras;
                        next unless @extras >= 2;

                        my @unit = _shared_unit($grid, @roof);
                        my %roof = map { _cell_key($_) => 1 } @roof;
                        my @eligible = grep {
                               !$_->value
                            && !$roof{ _cell_key($_) }
                            && _candidate_subset($_, \%extras)
                        } @unit;

                        my $needed = @extras - 1;
                        next if @eligible < $needed;

                        for my $companions (_combinations(\@eligible, $needed)) {
                            next unless _candidate_union_matches($companions, \%extras);

                            my %subset = (%roof, map { _cell_key($_) => 1 } @{$companions});
                            my $pattern = join q{, }, map { cell_label($_) } @cells;
                            my $companion_labels = join q{, },
                                map { cell_label($_) } @{$companions};
                            my $extra_text = join q{,}, @extras;

                            for my $target (@unit) {
                                next if $target->value;
                                next if $subset{ _cell_key($target) };

                                for my $value (@extras) {
                                    next unless $target->possibilities->[$value];

                                    my $key = join q{:},
                                        $target->row, $target->column, $value;
                                    next if $seen{$key}++;

                                    push @deductions, Sudoku::Deduction->new(
                                        strategy => $self->name,
                                        action   => 'remove_candidate',
                                        cell     => $target,
                                        value    => $value,
                                        cells    => [ @cells, @{$companions} ],
                                        reason   => sprintf(
                                            '%s and %s are the roof cells of a Unique '
                                            . 'Rectangle {%s}. Treating their extra '
                                            . 'candidates {%s} as one virtual cell, they '
                                            . 'combine with %s to form a naked subset in '
                                            . 'the shared roof unit. Therefore %s cannot '
                                            . 'contain %d.',
                                            cell_label($roof[0]),
                                            cell_label($roof[1]),
                                            $pair_key,
                                            $extra_text,
                                            $companion_labels,
                                            cell_label($target),
                                            $value,
                                        ),
                                        explanation => sprintf(
                                            'Remove candidate %d from %s. Rectangle cells: %s.',
                                            $value, cell_label($target), $pattern,
                                        ),
                                    );
                                }
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

sub _extras {
    my ($cell, @pair) = @_;
    my %pair = map { $_ => 1 } @pair;
    return grep { !$pair{$_} } candidate_values($cell);
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

sub _candidate_subset {
    my ($cell, $allowed) = @_;
    my @values = candidate_values($cell);
    return 0 unless @values;
    return !grep { !$allowed->{$_} } @values;
}

sub _candidate_union_matches {
    my ($cells, $wanted) = @_;
    my %found;
    $found{$_} = 1 for map { candidate_values($_) } @{$cells};
    return 0 unless keys(%found) == keys(%{$wanted});
    return !grep { !$found{$_} } keys %{$wanted};
}

sub _combinations {
    my ($items, $size, $start, $prefix) = @_;
    $start  //= 0;
    $prefix //= [];

    return ([ @{$prefix} ]) if @{$prefix} == $size;

    my @result;
    for my $index ($start .. $#{$items}) {
        push @result, _combinations(
            $items,
            $size,
            $index + 1,
            [ @{$prefix}, $items->[$index] ],
        );
    }

    return @result;
}

sub _cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

1;
