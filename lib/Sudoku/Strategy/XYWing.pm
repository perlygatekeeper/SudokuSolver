package Sudoku::Strategy::XYWing;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Wing qw(
    candidate_values
    cells_see_each_other
    common_peer_cells
    combinations
    cell_label
);

sub name {
    return 'XY-Wing';
}

sub apply {
    my ($self, $grid) = @_;

    my @bivalue_cells = grep {
           !$_->value
        && $_->possibilities->[0] == 2
    } @{ $grid->cells };

    my @deductions;
    my %seen;

    for my $pivot (@bivalue_cells) {
        my @pivot_values = candidate_values($pivot);
        my @pincers = grep {
               $_ != $pivot
            && cells_see_each_other($pivot, $_)
        } @bivalue_cells;

        for my $pair (combinations(\@pincers, 2)) {
            my ($left, $right) = @{$pair};
            my @left_values  = candidate_values($left);
            my @right_values = candidate_values($right);

            my @left_shared  = _intersection(\@pivot_values, \@left_values);
            my @right_shared = _intersection(\@pivot_values, \@right_values);

            next unless @left_shared == 1 && @right_shared == 1;
            next if $left_shared[0] == $right_shared[0];

            my @left_other  = grep { $_ != $left_shared[0] } @left_values;
            my @right_other = grep { $_ != $right_shared[0] } @right_values;

            next unless @left_other == 1 && @right_other == 1;
            next unless $left_other[0] == $right_other[0];

            my $elimination = $left_other[0];
            my @pattern = ($pivot, $left, $right);
            my $pattern_text = join q{, }, map { cell_label($_) } @pattern;

            for my $target (common_peer_cells($grid, $left, $right)) {
                next unless $target->possibilities->[$elimination];

                my $key = join q{:}, $target->row, $target->column, $elimination;
                next if $seen{$key}++;

                push @deductions, Sudoku::Deduction->new(
                    strategy    => $self->name,
                    action      => 'remove_candidate',
                    cell        => $target,
                    value       => $elimination,
                    cells       => \@pattern,
                    reason      => sprintf(
                        '%s is the pivot {%d,%d}; %s and %s are pincers '
                        . 'sharing candidate %d. Because %s sees both pincers, '
                        . 'it cannot contain %d.',
                        cell_label($pivot),
                        @pivot_values,
                        cell_label($left),
                        cell_label($right),
                        $elimination,
                        cell_label($target),
                        $elimination,
                    ),
                    explanation => sprintf(
                        'Remove candidate %d from %s. Pattern cells: %s.',
                        $elimination,
                        cell_label($target),
                        $pattern_text,
                    ),
                );
            }
        }
    }

    return @deductions;
}

sub _intersection {
    my ($left, $right) = @_;

    my %right = map { $_ => 1 } @{$right};
    return grep { $right{$_} } @{$left};
}

1;
