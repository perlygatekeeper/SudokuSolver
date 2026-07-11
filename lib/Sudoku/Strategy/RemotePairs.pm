package Sudoku::Strategy::RemotePairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;

sub name {
    return 'Remote Pairs';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;
    my %seen_deduction;
    my $pairs = $grid->pairs_possible;

    for my $pair_key (sort keys %{$pairs}) {
        my @pair_cells = @{ $pairs->{$pair_key} };
        next unless @pair_cells >= 4;

        my ($first_value, $second_value) = $pair_key =~ /^(\d)(\d)$/;
        next unless defined $first_value && defined $second_value;

        my @adjacency = map { [] } @pair_cells;

        for my $left (0 .. $#pair_cells - 1) {
            for my $right ($left + 1 .. $#pair_cells) {
                next unless _cells_see_each_other(
                    $pair_cells[$left],
                    $pair_cells[$right],
                );

                push @{ $adjacency[$left] },  $right;
                push @{ $adjacency[$right] }, $left;
            }
        }

        my @components = _bipartite_components(\@adjacency);
        my %is_pair_cell = map { _cell_key($_) => 1 } @pair_cells;

        for my $component (@components) {
            next unless $component->{valid};
            next unless @{ $component->{nodes} } >= 4;

            my @nodes = @{ $component->{nodes} };

            for my $left_position (0 .. $#nodes - 1) {
                my $left = $nodes[$left_position];

                for my $right_position ($left_position + 1 .. $#nodes) {
                    my $right = $nodes[$right_position];

                    next if $component->{color}{$left}
                        == $component->{color}{$right};

                    my @path = _shortest_path(
                        \@adjacency,
                        $left,
                        $right,
                    );

                    # Two cells form an ordinary naked pair.  A Remote Pairs
                    # chain requires at least four cells and therefore at
                    # least three links between its endpoints.
                    next unless @path >= 4;

                    my $left_endpoint  = $pair_cells[$left];
                    my $right_endpoint = $pair_cells[$right];

                    for my $target (@{ $grid->cells }) {
                        next if $target->value;
                        next if $is_pair_cell{ _cell_key($target) };
                        next unless _cells_see_each_other($target, $left_endpoint);
                        next unless _cells_see_each_other($target, $right_endpoint);

                        my @chain_cells = map { $pair_cells[$_] } @path;
                        my $chain_text = join q{ - }, map { _cell_label($_) } @chain_cells;
                        my $endpoint_text = sprintf '%s and %s',
                            _cell_label($left_endpoint),
                            _cell_label($right_endpoint);

                        for my $value ($first_value, $second_value) {
                            next unless $target->possibilities->[$value];

                            my $deduction_key = join q{:},
                                $target->row,
                                $target->column,
                                $value;
                            next if $seen_deduction{$deduction_key}++;

                            my $reason = sprintf(
                                'Cells %s form an alternating {%d,%d} chain. '
                                . '%s sees opposite endpoints %s, so one endpoint '
                                . 'must contain %d and %s cannot contain %d.',
                                $chain_text,
                                $first_value,
                                $second_value,
                                _cell_label($target),
                                $endpoint_text,
                                $value,
                                _cell_label($target),
                                $value,
                            );

                            push @deductions, Sudoku::Deduction->new(
                                strategy    => $self->name,
                                action      => 'remove_candidate',
                                cell        => $target,
                                value       => $value,
                                cells       => \@chain_cells,
                                reason      => $reason,
                                explanation => sprintf(
                                    'Remove candidate %d from %s.',
                                    $value,
                                    _cell_label($target),
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

sub _bipartite_components {
    my ($adjacency) = @_;

    my %visited;
    my @components;

    for my $start (0 .. $#{$adjacency}) {
        next if $visited{$start};

        my @queue = ($start);
        my %color = ($start => 0);
        my @nodes;
        my $valid = 1;
        $visited{$start} = 1;

        while (@queue) {
            my $current = shift @queue;
            push @nodes, $current;

            for my $neighbor (@{ $adjacency->[$current] }) {
                if (!exists $color{$neighbor}) {
                    $color{$neighbor} = 1 - $color{$current};
                    $visited{$neighbor} = 1;
                    push @queue, $neighbor;
                    next;
                }

                $valid = 0
                    if $color{$neighbor} == $color{$current};
            }
        }

        push @components, {
            nodes => \@nodes,
            color => \%color,
            valid => $valid,
        };
    }

    return @components;
}

sub _shortest_path {
    my ($adjacency, $start, $finish) = @_;

    my @queue = ($start);
    my %visited = ($start => 1);
    my %parent;

    while (@queue) {
        my $current = shift @queue;
        last if $current == $finish;

        for my $neighbor (@{ $adjacency->[$current] }) {
            next if $visited{$neighbor};

            $visited{$neighbor} = 1;
            $parent{$neighbor} = $current;
            push @queue, $neighbor;
        }
    }

    return unless $visited{$finish};

    my @path = ($finish);
    my $current = $finish;

    while ($current != $start) {
        $current = $parent{$current};
        unshift @path, $current;
    }

    return @path;
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

sub _cell_label {
    my ($cell) = @_;

    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

1;
