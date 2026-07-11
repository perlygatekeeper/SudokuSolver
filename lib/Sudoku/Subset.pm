package Sudoku::Subset;

use strict;
use warnings;

sub naked_subsets {
    my ($class, $unit, $size) = @_;

    my @eligible = grep {
        !$_->value
            && $_->possibilities->[0] >= 2
            && $_->possibilities->[0] <= $size
    } @{$unit};

    my @subsets;

    for my $cells (_combinations(\@eligible, $size)) {
        my %values;
        for my $cell (@{$cells}) {
            $values{$_} = 1 for _candidate_values($cell);
        }

        next unless keys(%values) == $size;

        my @contained = grep {
            !$_->value && _candidates_are_subset($_, \%values)
        } @{$unit};

        next unless @contained == $size;

        push @subsets, {
            cells  => [ @{$cells} ],
            values => [ sort { $a <=> $b } keys %values ],
        };
    }

    return @subsets;
}

sub hidden_subsets {
    my ($class, $unit, $size) = @_;

    my @unsolved = grep { !$_->value } @{$unit};
    my @values   = 1 .. 9;
    my @subsets;

    for my $selected (_combinations(\@values, $size)) {
        my %selected = map { $_ => 1 } @{$selected};
        my %cells;
        my $valid = 1;

        for my $value (@{$selected}) {
            my @places = grep { $_->possibilities->[$value] } @unsolved;

            # A value restricted to one cell is a Hidden Single, not a
            # Hidden Subset of this size.  It should be handled earlier.
            if (@places < 2 || @places > $size) {
                $valid = 0;
                last;
            }

            $cells{ _cell_key($_) } = $_ for @places;
        }

        next unless $valid;
        next unless keys(%cells) == $size;

        push @subsets, {
            cells  => [ sort {
                $a->row <=> $b->row || $a->column <=> $b->column
            } values %cells ],
            values => [ @{$selected} ],
        };
    }

    return @subsets;
}

sub _candidate_values {
    my ($cell) = @_;
    return grep { $cell->possibilities->[$_] } 1 .. 9;
}

sub _candidates_are_subset {
    my ($cell, $values) = @_;

    for my $candidate (_candidate_values($cell)) {
        return 0 unless $values->{$candidate};
    }

    return 1;
}

sub _cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

sub _combinations {
    my ($items, $size) = @_;

    return () if $size < 1 || @{$items} < $size;

    my @results;
    _collect_combinations($items, $size, 0, [], \@results);
    return @results;
}

sub _collect_combinations {
    my ($items, $size, $start, $chosen, $results) = @_;

    if (@{$chosen} == $size) {
        push @{$results}, [ @{$chosen} ];
        return;
    }

    my $remaining = $size - @{$chosen};
    my $last = @{$items} - $remaining;

    for my $index ($start .. $last) {
        push @{$chosen}, $items->[$index];
        _collect_combinations($items, $size, $index + 1, $chosen, $results);
        pop @{$chosen};
    }

    return;
}

1;
