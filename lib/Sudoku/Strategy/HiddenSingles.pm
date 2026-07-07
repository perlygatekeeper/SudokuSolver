package Sudoku::Strategy::HiddenSingles;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Hidden Singles';
}

sub apply {
    my ($self, $grid) = @_;

    my $progress = 0;
    my $possible_value;
    my $possibility_counts;

    print "Looking for Lone representatives (possible value's present in only one cell of a cluster [row column or box]):\n";

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (sort grep { $_ =~ /box/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/box\d://;
        $progress += $self->_set_hidden_single(
            $grid,
            $possibility_counts->{$key}[0],
            $possible_value,
            'Lone in Box   ',
        );
    }

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (grep { $_ =~ /row/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/row\d://;
        $progress += $self->_set_hidden_single(
            $grid,
            $possibility_counts->{$key}[0],
            $possible_value,
            'Lone in Row   ',
        );
    }

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (grep { $_ =~ /col/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/col\d://;
        $progress += $self->_set_hidden_single(
            $grid,
            $possibility_counts->{$key}[0],
            $possible_value,
            'Lone in Column',
        );
    }

    print "Found and set $progress cells this lone representatives search pass.\n\n";
    return $progress;
}

sub _set_hidden_single {
    my ($self, $grid, $cell, $value, $label) = @_;

    return 0 if $cell->value;

    $grid->solved(1 + $grid->solved);
    $cell->value($value);
    $cell->possibilities([ (0) x 10 ]);
    $grid->remove_my_solution_from_my_mates($cell);

    printf "%s Setting cell ( %d, %d, %d ) to %d\n",
        $label,
        ($cell->row + 1),
        ($cell->column + 1),
        ($cell->box + 1),
        $value;

    return 1;
}

1;
