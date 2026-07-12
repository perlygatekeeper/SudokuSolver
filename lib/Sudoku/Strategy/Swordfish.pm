package Sudoku::Strategy::Swordfish;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Fish qw(find_fish_patterns cell_label);

sub name {
    return 'Swordfish';
}

sub apply {
    my ( $self, $grid ) = @_;

    my @deductions;
    my %seen;

    for my $pattern (find_fish_patterns($grid, 3)) {
        my $value = $pattern->{value};
        my $orientation = $pattern->{orientation};
        my $base_name = $orientation eq 'row' ? 'rows' : 'columns';
        my $cover_name = $orientation eq 'row' ? 'columns' : 'rows';
        my $base_text = join q{, }, map { $_ + 1 } @{ $pattern->{base_indices} };
        my $cover_text = join q{, }, map { $_ + 1 } @{ $pattern->{cover_indices} };
        my $corner_text = join q{, }, map { cell_label($_) } @{ $pattern->{pattern_cells} };

        for my $target (@{ $pattern->{targets} }) {
            my $key = join q{:}, $target->row, $target->column, $value;
            next if $seen{$key}++;

            push @deductions, Sudoku::Deduction->new(
                strategy => $self->name,
                action   => 'remove_candidate',
                cell     => $target,
                value    => $value,
                cells    => [ @{ $pattern->{pattern_cells} } ],
                reason   => sprintf(
                    'Candidate %d is confined to %s %s across %s %s. '
                    . 'Those three base units must place %d within the same '
                    . 'three cover units, so %s cannot contain %d.',
                    $value,
                    $cover_name,
                    $cover_text,
                    $base_name,
                    $base_text,
                    $value,
                    cell_label($target),
                    $value,
                ),
                explanation => sprintf(
                    'Remove candidate %d from %s. Swordfish cells: %s.',
                    $value,
                    cell_label($target),
                    $corner_text,
                ),
            );
        }
    }

    return @deductions;
}

1;
