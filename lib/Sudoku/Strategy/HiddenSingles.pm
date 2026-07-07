package Sudoku::Strategy::HiddenSingles;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;

sub name {
    return 'Hidden Singles';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;
    my $possible_value;
    my $possibility_counts;

    print "Looking for Lone representatives (possible value's present in only one cell of a cluster [row column or box]):\n";

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (sort grep { $_ =~ /box/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/box\d://;
        my $deduction = $self->_hidden_single_deduction(
            $possibility_counts->{$key}[0],
            $possible_value,
            'box',
            'Lone in Box   ',
        );
        push @deductions, $deduction if $deduction;
    }

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (grep { $_ =~ /row/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/row\d://;
        my $deduction = $self->_hidden_single_deduction(
            $possibility_counts->{$key}[0],
            $possible_value,
            'row',
            'Lone in Row   ',
        );
        push @deductions, $deduction if $deduction;
    }

    $possibility_counts = $grid->possibilities_hash;

    foreach my $key (grep { $_ =~ /col/ } keys %{ $possibility_counts }) {
        next unless scalar(@{ $possibility_counts->{$key} }) == 1;

        ($possible_value = $key) =~ s/col\d://;
        my $deduction = $self->_hidden_single_deduction(
            $possibility_counts->{$key}[0],
            $possible_value,
            'column',
            'Lone in Column',
        );
        push @deductions, $deduction if $deduction;
    }

    print "Found and set " . scalar(@deductions) . " cells this lone representatives search pass.\n\n";
    return @deductions;
}

sub _hidden_single_deduction {
    my ($self, $cell, $value, $unit_type, $label) = @_;

    return if $cell->value;

    return Sudoku::Deduction->new(
        strategy    => $self->name,
        action      => 'set_value',
        cell        => $cell,
        value       => $value,
        reason      => $label,
        explanation => sprintf(
            'Candidate %d appears only once in this %s, so R%dC%d must be %d.',
            $value,
            $unit_type,
            $cell->row + 1,
            $cell->column + 1,
            $value,
        ),
    );
}

1;
