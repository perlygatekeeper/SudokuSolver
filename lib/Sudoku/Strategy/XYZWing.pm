package Sudoku::Strategy::XYZWing;

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
    return 'XYZ-Wing';
}

sub apply {
    my ($self, $grid) = @_;

    my @pivots = grep {
           !$_->value
        && $_->possibilities->[0] == 3
    } @{ $grid->cells };

    my @bivalue_cells = grep {
           !$_->value
        && $_->possibilities->[0] == 2
    } @{ $grid->cells };

    my @deductions;
    my %seen;

    for my $pivot (@pivots) {
        my @pivot_values = candidate_values($pivot);
        my %pivot_value = map { $_ => 1 } @pivot_values;

        my @pincers = grep {
               cells_see_each_other($pivot, $_)
            && _is_subset([ candidate_values($_) ], \%pivot_value)
        } @bivalue_cells;

        for my $pair (combinations(\@pincers, 2)) {
            my ($left, $right) = @{$pair};
            my @left_values  = candidate_values($left);
            my @right_values = candidate_values($right);
            my @shared = _intersection(\@left_values, \@right_values);

            next unless @shared == 1;
            my $elimination = $shared[0];

            my %union = map { $_ => 1 } (@left_values, @right_values);
            next unless keys(%union) == 3;
            next unless _same_set([ sort keys %union ], \@pivot_values);

            my @pattern = ($pivot, $left, $right);
            my $pattern_text = join q{, }, map { cell_label($_) } @pattern;

            for my $target (common_peer_cells($grid, @pattern)) {
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
                        '%s contains {%s}; pincers %s and %s share candidate %d. '
                        . '%s sees the pivot and both pincers, so it cannot contain %d.',
                        cell_label($pivot),
                        join(q{,}, @pivot_values),
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

sub _is_subset {
    my ($values, $allowed) = @_;

    for my $value (@{$values}) {
        return 0 unless $allowed->{$value};
    }

    return 1;
}

sub _same_set {
    my ($left, $right) = @_;

    return 0 unless @{$left} == @{$right};
    return join(q{:}, sort { $a <=> $b } @{$left})
        eq join(q{:}, sort { $a <=> $b } @{$right});
}

1;
