package Sudoku::Strategy::WXYZWing;

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
    return 'WXYZ-Wing';
}

sub apply {
    my ($self, $grid) = @_;

    my @pivots = grep {
           !$_->value
        && $_->possibilities->[0] == 4
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

        for my $triple (combinations(\@pincers, 3)) {
            my @pincer_values = map { [ candidate_values($_) ] } @{$triple};
            my @shared = _intersection_many(@pincer_values);

            next unless @shared == 1;
            my $elimination = $shared[0];

            my @other_values;
            my $valid = 1;

            for my $values (@pincer_values) {
                my @other = grep { $_ != $elimination } @{$values};
                if (@other != 1) {
                    $valid = 0;
                    last;
                }
                push @other_values, $other[0];
            }

            next unless $valid;
            my %other = map { $_ => 1 } @other_values;
            next unless keys(%other) == 3;

            my %expected = (%other, $elimination => 1);
            next unless _same_set([ sort keys %expected ], \@pivot_values);

            my @pattern = ($pivot, @{$triple});
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
                        '%s contains {%s}; the three pincers %s all contain %d '
                        . 'and pair it with three different pivot candidates. '
                        . '%s sees every pattern cell, so it cannot contain %d.',
                        cell_label($pivot),
                        join(q{,}, @pivot_values),
                        join(q{, }, map { cell_label($_) } @{$triple}),
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

sub _intersection_many {
    my (@sets) = @_;

    return unless @sets;

    my %common = map { $_ => 1 } @{ shift @sets };
    for my $set (@sets) {
        my %present = map { $_ => 1 } @{$set};
        delete $common{$_} for grep { !$present{$_} } keys %common;
    }

    return sort { $a <=> $b } keys %common;
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
