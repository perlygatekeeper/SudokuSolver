package Sudoku::Strategy::SimpleColoring;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(cell_label);
use Sudoku::StrongLinks qw(
    candidate_graph_for_digit
    connected_components
    cell_key
    cells_see_each_other
);

sub name {
    return 'Simple Coloring';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $digit (1 .. 9) {
        my $graph = candidate_graph_for_digit($grid, $digit);

        for my $component (connected_components($graph)) {
            next unless @{ $component->{keys} } >= 2;

            my ( $colors, $conflicted ) = _color_component($graph, $component);
            next if $conflicted;

            _add_color_wrap_deductions(
                $self, $digit, $graph, $component, $colors,
                \%seen, \@deductions,
            );
            _add_color_trap_deductions(
                $self, $grid, $digit, $graph, $component, $colors,
                \%seen, \@deductions,
            );
        }
    }

    return @deductions;
}

sub _color_component {
    my ( $graph, $component ) = @_;

    my %color;
    my @queue = ( $component->{keys}[0] );
    $color{ $component->{keys}[0] } = 0;
    my $conflicted = 0;

    while (@queue) {
        my $key = shift @queue;

        for my $neighbor (keys %{ $graph->{neighbors}{$key} || {} }) {
            my $expected = 1 - $color{$key};

            if (exists $color{$neighbor}) {
                $conflicted = 1 if $color{$neighbor} != $expected;
                next;
            }

            $color{$neighbor} = $expected;
            push @queue, $neighbor;
        }
    }

    return ( \%color, $conflicted );
}

sub _add_color_wrap_deductions {
    my ( $self, $digit, $graph, $component, $colors, $seen, $out ) = @_;

    for my $color (0, 1) {
        my @cells = map { $graph->{nodes}{$_} }
            grep { $colors->{$_} == $color } @{ $component->{keys} };

        my ($conflict_first, $conflict_second);
        OUTER:
        for my $first_index (0 .. $#cells - 1) {
            for my $second_index ($first_index + 1 .. $#cells) {
                next unless cells_see_each_other(
                    $cells[$first_index], $cells[$second_index],
                );
                ($conflict_first, $conflict_second)
                    = @cells[$first_index, $second_index];
                last OUTER;
            }
        }

        next unless $conflict_first;

        my $color_name = $color ? 'B' : 'A';
        my $opposite_name = $color ? 'A' : 'B';

        for my $target (@cells) {
            my $key = join q{:}, cell_key($target), $digit;
            next if $seen->{$key}++;

            push @{$out}, Sudoku::Deduction->new(
                strategy => $self->name,
                action   => 'remove_candidate',
                cell     => $target,
                value    => $digit,
                cells    => [ @{ $component->{cells} } ],
                reason   => sprintf(
                    'Simple Coloring assigns candidate %d alternately to colors A and B along strong links. '
                    . '%s and %s both have color %s and see each other, so color %s is contradictory. '
                    . 'Every color-%s candidate is false; remove %d from %s.',
                    $digit,
                    cell_label($conflict_first),
                    cell_label($conflict_second),
                    $color_name,
                    $color_name,
                    $color_name,
                    $digit,
                    cell_label($target),
                ),
                explanation => sprintf(
                    'Remove candidate %d from %s. Simple Coloring wrap: color %s is false because %s and %s see each other.',
                    $digit,
                    cell_label($target),
                    $color_name,
                    cell_label($conflict_first),
                    cell_label($conflict_second),
                ),
            );
        }
    }
}

sub _add_color_trap_deductions {
    my ( $self, $grid, $digit, $graph, $component, $colors, $seen, $out ) = @_;

    my %component_key = map { $_ => 1 } @{ $component->{keys} };
    my @color_cells;
    for my $color (0, 1) {
        $color_cells[$color] = [
            map { $graph->{nodes}{$_} }
            grep { $colors->{$_} == $color } @{ $component->{keys} }
        ];
    }

    for my $target (@{ $grid->cells }) {
        next if $target->value;
        next unless $target->possibilities->[$digit];
        next if $component_key{ cell_key($target) };

        my ($seen_a) = grep { cells_see_each_other($target, $_) }
            @{ $color_cells[0] };
        my ($seen_b) = grep { cells_see_each_other($target, $_) }
            @{ $color_cells[1] };
        next unless $seen_a && $seen_b;

        my $key = join q{:}, cell_key($target), $digit;
        next if $seen->{$key}++;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $digit,
            cells    => [ @{ $component->{cells} } ],
            reason   => sprintf(
                'Simple Coloring assigns candidate %d alternately to colors A and B along strong links. '
                . '%s sees color A at %s and color B at %s. One color must be true, so %s cannot contain %d.',
                $digit,
                cell_label($target),
                cell_label($seen_a),
                cell_label($seen_b),
                cell_label($target),
                $digit,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. Simple Coloring trap: it sees both colors at %s and %s.',
                $digit,
                cell_label($target),
                cell_label($seen_a),
                cell_label($seen_b),
            ),
        );
    }
}

1;
