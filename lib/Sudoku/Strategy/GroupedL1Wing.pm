package Sudoku::Strategy::GroupedL1Wing;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::InferenceNode;
use Sudoku::StrongLinks qw(
    strong_links_for_digit
    grouped_strong_links_for_digit
    nodes_are_weakly_linked
    cell_sees_node
);

sub name {
    return 'Grouped L1-Wing';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $digit (1 .. 9) {
        my @links = _all_strong_links($grid, $digit);

        for my $first_link (@links) {
            for my $second_link (@links) {
                next if $first_link == $second_link;

                for my $first_orientation (0, 1) {
                    my $left  = $first_link->{nodes}[$first_orientation];
                    my $inner_left = $first_link->{nodes}[1 - $first_orientation];

                    for my $second_orientation (0, 1) {
                        my $inner_right = $second_link->{nodes}[$second_orientation];
                        my $right = $second_link->{nodes}[1 - $second_orientation];

                        next unless grep { $_->is_group }
                            ($left, $inner_left, $inner_right, $right);
                        next unless nodes_are_weakly_linked(
                            $inner_left, $inner_right,
                        );
                        next if _chain_overlaps(
                            $left, $inner_left, $inner_right, $right,
                        );

                        _add_eliminations(
                            $self, $grid, $digit,
                            $left, $inner_left, $inner_right, $right,
                            \%seen, \@deductions,
                        );
                    }
                }
            }
        }
    }

    return @deductions;
}

sub _add_eliminations {
    my (
        $self, $grid, $digit,
        $left, $inner_left, $inner_right, $right,
        $seen, $out,
    ) = @_;

    my @chain_nodes = ($left, $inner_left, $inner_right, $right);

    for my $target ( @{ $grid->cells } ) {
        next if $target->value;
        next unless $target->possibilities->[$digit];
        next if grep { $_->contains_cell($target) } @chain_nodes;
        next unless cell_sees_node($target, $left);
        next unless cell_sees_node($target, $right);

        my $key = join q{:}, $target->row, $target->column, $digit;
        next if $seen->{$key}++;

        my $chain = join q{ },
            $left->label,
            '=S=',
            $inner_left->label,
            '-W-',
            $inner_right->label,
            '=S=',
            $right->label;

        push @{$out}, Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $target,
            value    => $digit,
            cells    => [
                map { @{ $_->cells } } @chain_nodes
            ],
            reason   => sprintf(
                'The grouped L1-Wing %s contains two strong links joined by '
                . 'a weak link. If the left endpoint is false, the chain '
                . 'forces the right endpoint true, so at least one endpoint '
                . 'contains %d. %s sees every possible location in both '
                . 'endpoints and therefore cannot contain %d.',
                $chain,
                $digit,
                _cell_label($target),
                $digit,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. Grouped L1-Wing endpoints %s '
                . 'and %s cannot both be false.',
                $digit,
                _cell_label($target),
                $left->label,
                $right->label,
            ),
        );
    }
}

sub _all_strong_links {
    my ( $grid, $digit ) = @_;

    my @links = grouped_strong_links_for_digit($grid, $digit);

    for my $link ( strong_links_for_digit($grid, $digit) ) {
        push @links, {
            type  => $link->{type},
            index => $link->{index},
            nodes => [ map {
                Sudoku::InferenceNode->new(
                    digit => $digit,
                    cells => [$_],
                )
            } @{ $link->{cells} } ],
        };
    }

    my %seen;
    return grep {
        my $key = join q{|}, sort map { $_->key } @{ $_->{nodes} };
        !$seen{$key}++;
    } @links;
}

sub _chain_overlaps {
    my @nodes = @_;

    for my $first_index (0 .. $#nodes - 1) {
        for my $second_index ($first_index + 1 .. $#nodes) {
            return 1 if $nodes[$first_index]->overlaps($nodes[$second_index]);
        }
    }

    return 0;
}

sub _cell_label {
    my ($cell) = @_;
    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

1;
