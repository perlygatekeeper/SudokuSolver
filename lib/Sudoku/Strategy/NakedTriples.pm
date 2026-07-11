package Sudoku::Strategy::NakedTriples;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Subset;

sub name {
    return 'Naked Triples';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;
    my %seen;

    for my $unit ($self->_units($grid)) {
        for my $subset (Sudoku::Subset->naked_subsets($unit->{cells}, 3)) {
            my %member = map { _cell_key($_) => 1 } @{ $subset->{cells} };
            my $values = join q{, }, @{ $subset->{values} };
            my $locations = join q{, }, map { _cell_name($_) } @{ $subset->{cells} };

            for my $cell (grep { !$_->value && !$member{ _cell_key($_) } } @{ $unit->{cells} }) {
                for my $value (@{ $subset->{values} }) {
                    next unless $cell->possibilities->[$value];

                    my $key = join q{:}, _cell_key($cell), $value;
                    next if $seen{$key}++;

                    my $reason = sprintf(
                        'Cells %s form a Naked Triple {%s} in %s %d, so no other cell in that unit can contain %d.',
                        $locations,
                        $values,
                        $unit->{type},
                        $unit->{index} + 1,
                        $value,
                    );

                    push @deductions, $self->_remove_candidate_deduction(
                        $cell,
                        $value,
                        $reason,
                    );
                }
            }
        }
    }

    return @deductions;
}

sub _units {
    my ($self, $grid) = @_;

    return (
        map({ { type => 'row',    index => $_, cells => $grid->rows->[$_]    } } 0 .. 8),
        map({ { type => 'column', index => $_, cells => $grid->columns->[$_] } } 0 .. 8),
        map({ { type => 'box',    index => $_, cells => $grid->boxes->[$_]   } } 0 .. 8),
    );
}

sub _cell_key {
    my ($cell) = @_;
    return join q{:}, $cell->row, $cell->column;
}

sub _cell_name {
    my ($cell) = @_;
    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

1;
