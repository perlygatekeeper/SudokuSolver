package Sudoku::Strategy::NakedSingles;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;

sub name {
    return 'Naked Singles';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;


    for my $cell (@{ $grid->cells }) {
        next if $cell->value;
        next unless $cell->possibilities->[0] == 1;

        my ($value) = grep { $cell->possibilities->[$_] } 1 .. 9;
        next unless $value;

        push @deductions, Sudoku::Deduction->new(
            strategy    => $self->name,
            action      => 'set_value',
            cell        => $cell,
            value       => $value,
            reason      => 'Only one candidate remains in the cell.',
            explanation => sprintf(
                'Cell R%dC%d has only candidate %d remaining.',
                $cell->row + 1,
                $cell->column + 1,
                $value,
            ),
        );
    }

    return @deductions;
}

1;
