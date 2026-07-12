package Sudoku::Strategy::MultiColoring;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);
use Sudoku::StrongLinks qw(
    candidate_graph_for_digit
    connected_components
    color_component
    cell_key
    cells_see_each_other
);

sub name {
    return 'Multi-Coloring';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $digit (1 .. 9) {
        my $graph = candidate_graph_for_digit($grid, $digit);
        my @colored;

        for my $component (connected_components($graph)) {
            next unless @{ $component->{keys} } >= 2;

            my ( $colors, $conflicted ) = color_component($graph, $component);
            next if $conflicted;

            push @colored, {
                component => $component,
                colors    => $colors,
            };
        }

        for my $first_index (0 .. $#colored - 1) {
            for my $second_index ($first_index + 1 .. $#colored) {
                my $first  = $colored[$first_index];
                my $second = $colored[$second_index];

                _add_color_collision_deductions(
                    $self, $digit, $graph, $first, $second,
                    \%seen, \@deductions,
                );
                _add_color_collision_deductions(
                    $self, $digit, $graph, $second, $first,
                    \%seen, \@deductions,
                );
                _add_color_wing_deductions(
                    $self, $grid, $digit, $graph, $first, $second,
                    \%seen, \@deductions,
                );
            }
        }
    }

    return @deductions;
}

sub _cells_for_color {
    my ( $graph, $colored, $color ) = @_;

    return map { $graph->{nodes}{$_} }
        grep { $colored->{colors}{$_} == $color }
        @{ $colored->{component}{keys} };
}

sub _add_color_collision_deductions {
    my ( $self, $digit, $graph, $source, $other, $seen, $out ) = @_;

    for my $source_color (0, 1) {
        my @source_cells = _cells_for_color($graph, $source, $source_color);
        my @other_a = _cells_for_color($graph, $other, 0);
        my @other_b = _cells_for_color($graph, $other, 1);

        my ($witness_a, $seen_a);
        my ($witness_b, $seen_b);

        for my $source_cell (@source_cells) {
            ($seen_a) = grep {
                cells_see_each_other($source_cell, $_)
            } @other_a unless $seen_a;
            $witness_a = $source_cell if $seen_a && !$witness_a;

            ($seen_b) = grep {
                cells_see_each_other($source_cell, $_)
            } @other_b unless $seen_b;
            $witness_b = $source_cell if $seen_b && !$witness_b;
        }

        next unless $seen_a && $seen_b;

        my $color_name = $source_color ? 'B' : 'A';
        my @pattern_cells = (
            @{ $source->{component}{cells} },
            @{ $other->{component}{cells} },
        );

        for my $target (@source_cells) {
            my $key = join q{:}, cell_key($target), $digit;
            next if $seen->{$key}++;

            push @{$out}, Sudoku::Deduction->new(
                strategy => $self->name,
                action   => 'remove_candidate',
                cell     => $target,
                value    => $digit,
                cells    => \@pattern_cells,
                reason   => sprintf(
                    'Multi-Coloring assigns candidate %d to two separate strong-link components. '
                    . 'Source color %s sees both colors of the other component: %s sees %s and %s sees %s. '
                    . 'If source color %s were true, both colors of the other component would be false, which is impossible. '
                    . 'Therefore source color %s is false; remove %d from %s.',
                    $digit,
                    $color_name,
                    cell_label($witness_a),
                    cell_label($seen_a),
                    cell_label($witness_b),
                    cell_label($seen_b),
                    $color_name,
                    $color_name,
                    $digit,
                    cell_label($target),
                ),
                explanation => sprintf(
                    'Remove candidate %d from %s. Multi-Coloring collision: its color sees both colors of another component.',
                    $digit,
                    cell_label($target),
                ),
            );
        }
    }
}

sub _add_color_wing_deductions {
    my ( $self, $grid, $digit, $graph, $first, $second, $seen, $out ) = @_;

    my %component_key = map { $_ => 1 } (
        @{ $first->{component}{keys} },
        @{ $second->{component}{keys} },
    );

    for my $first_color (0, 1) {
        for my $second_color (0, 1) {
            my @first_same  = _cells_for_color($graph, $first,  $first_color);
            my @second_same = _cells_for_color($graph, $second, $second_color);

            my ($contact_first, $contact_second);
            CONTACT:
            for my $first_cell (@first_same) {
                for my $second_cell (@second_same) {
                    next unless cells_see_each_other(
                        $first_cell, $second_cell,
                    );
                    ($contact_first, $contact_second)
                        = ($first_cell, $second_cell);
                    last CONTACT;
                }
            }
            next unless $contact_first;

            my @first_opposite
                = _cells_for_color($graph, $first,  1 - $first_color);
            my @second_opposite
                = _cells_for_color($graph, $second, 1 - $second_color);

            for my $target (@{ $grid->cells }) {
                next if $target->value;
                next unless $target->possibilities->[$digit];
                next if $component_key{ cell_key($target) };

                my ($seen_first) = grep {
                    cells_see_each_other($target, $_)
                } @first_opposite;
                my ($seen_second) = grep {
                    cells_see_each_other($target, $_)
                } @second_opposite;
                next unless $seen_first && $seen_second;

                my $key = join q{:}, cell_key($target), $digit;
                next if $seen->{$key}++;

                my @pattern_cells = (
                    @{ $first->{component}{cells} },
                    @{ $second->{component}{cells} },
                );

                push @{$out}, Sudoku::Deduction->new(
                    strategy => $self->name,
                    action   => 'remove_candidate',
                    cell     => $target,
                    value    => $digit,
                    cells    => \@pattern_cells,
                    reason   => sprintf(
                        'Multi-Coloring assigns candidate %d to two separate strong-link components. '
                        . '%s and %s are same-color candidates from different components and see each other, '
                        . 'so they cannot both be true. Therefore at least one opposite color, represented by %s and %s, must be true. '
                        . '%s sees both opposite colors and cannot contain %d.',
                        $digit,
                        cell_label($contact_first),
                        cell_label($contact_second),
                        cell_label($seen_first),
                        cell_label($seen_second),
                        cell_label($target),
                        $digit,
                    ),
                    explanation => sprintf(
                        'Remove candidate %d from %s. Multi-Coloring wing: it sees the two opposite colors forced by a cross-component color contact.',
                        $digit,
                        cell_label($target),
                    ),
                );
            }
        }
    }
}

1;
