package Sudoku::Strategy::PointingClaiming;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;

sub name {
    return 'Pointing / Claiming';
}

sub apply {
    my ($self, $grid) = @_;

    my @deductions;
    my %seen;

    print "Looking for Imaginary Values\n";

    for my $value (1 .. 9) {
        push @deductions, $self->_pointing_deductions($grid, $value, \%seen);
        push @deductions, $self->_claiming_row_deductions($grid, $value, \%seen);
        push @deductions, $self->_claiming_column_deductions($grid, $value, \%seen);
    }

    return @deductions;
}

sub _pointing_deductions {
    my ($self, $grid, $value, $seen) = @_;

    my @deductions;

    for my $box (0 .. 8) {
        my @cells = grep { _has_candidate($_, $value) } @{ $grid->boxes->[$box] };
        next unless @cells;

        my %rows = map { $_->row    => 1 } @cells;
        my %cols = map { $_->column => 1 } @cells;

        if (keys(%rows) == 1) {
            my ($row) = keys %rows;
            push @deductions, $self->_remove_from_row_outside_box(
                $grid,
                $value,
                $row,
                $box,
                $seen,
            );
        }

        if (keys(%cols) == 1) {
            my ($column) = keys %cols;
            push @deductions, $self->_remove_from_column_outside_box(
                $grid,
                $value,
                $column,
                $box,
                $seen,
            );
        }
    }

    return @deductions;
}

sub _claiming_row_deductions {
    my ($self, $grid, $value, $seen) = @_;

    my @deductions;

    for my $row (0 .. 8) {
        my @cells = grep { _has_candidate($_, $value) } @{ $grid->rows->[$row] };
        next unless @cells;

        my %boxes = map { $_->box => 1 } @cells;
        next unless keys(%boxes) == 1;

        my ($box) = keys %boxes;
        push @deductions, $self->_remove_from_box_outside_row(
            $grid,
            $value,
            $box,
            $row,
            $seen,
        );
    }

    return @deductions;
}

sub _claiming_column_deductions {
    my ($self, $grid, $value, $seen) = @_;

    my @deductions;

    for my $column (0 .. 8) {
        my @cells = grep { _has_candidate($_, $value) } @{ $grid->columns->[$column] };
        next unless @cells;

        my %boxes = map { $_->box => 1 } @cells;
        next unless keys(%boxes) == 1;

        my ($box) = keys %boxes;
        push @deductions, $self->_remove_from_box_outside_column(
            $grid,
            $value,
            $box,
            $column,
            $seen,
        );
    }

    return @deductions;
}

sub _remove_from_row_outside_box {
    my ($self, $grid, $value, $row, $box, $seen) = @_;

    return map {
        $self->_remove_candidate_deduction(
            $_,
            $value,
            $seen,
            sprintf(
                'Candidate %d is confined to row %d inside box %d.',
                $value,
                $row + 1,
                $box + 1,
            ),
        )
    } grep { $_->box != $box && _has_candidate($_, $value) } @{ $grid->rows->[$row] };
}

sub _remove_from_column_outside_box {
    my ($self, $grid, $value, $column, $box, $seen) = @_;

    return map {
        $self->_remove_candidate_deduction(
            $_,
            $value,
            $seen,
            sprintf(
                'Candidate %d is confined to column %d inside box %d.',
                $value,
                $column + 1,
                $box + 1,
            ),
        )
    } grep { $_->box != $box && _has_candidate($_, $value) } @{ $grid->columns->[$column] };
}

sub _remove_from_box_outside_row {
    my ($self, $grid, $value, $box, $row, $seen) = @_;

    return map {
        $self->_remove_candidate_deduction(
            $_,
            $value,
            $seen,
            sprintf(
                'Candidate %d is confined to box %d within row %d.',
                $value,
                $box + 1,
                $row + 1,
            ),
        )
    } grep { $_->row != $row && _has_candidate($_, $value) } @{ $grid->boxes->[$box] };
}

sub _remove_from_box_outside_column {
    my ($self, $grid, $value, $box, $column, $seen) = @_;

    return map {
        $self->_remove_candidate_deduction(
            $_,
            $value,
            $seen,
            sprintf(
                'Candidate %d is confined to box %d within column %d.',
                $value,
                $box + 1,
                $column + 1,
            ),
        )
    } grep { $_->column != $column && _has_candidate($_, $value) } @{ $grid->boxes->[$box] };
}

sub _remove_candidate_deduction {
    my ($self, $cell, $value, $seen, $reason) = @_;

    my $key = join q{:}, $cell->row, $cell->column, $value;
    return if $seen->{$key}++;

    return Sudoku::Deduction->new(
        strategy    => $self->name,
        action      => 'remove_candidate',
        cell        => $cell,
        value       => $value,
        reason      => $reason,
        explanation => sprintf(
            'Remove candidate %d from R%dC%d.',
            $value,
            $cell->row + 1,
            $cell->column + 1,
        ),
    );
}

sub _has_candidate {
    my ($cell, $value) = @_;

    return 0 if $cell->value;
    return $cell->possibilities->[$value] ? 1 : 0;
}

1;
