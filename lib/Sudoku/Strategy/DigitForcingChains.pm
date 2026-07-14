package Sudoku::Strategy::DigitForcingChains;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Hypothetical;

use constant MAX_BRANCH_STEPS => 100;

my @DEFAULT_PROPAGATION_STRATEGIES = qw(
    Sudoku::Strategy::NakedSingles
    Sudoku::Strategy::HiddenSingles
    Sudoku::Strategy::PointingClaiming
    Sudoku::Strategy::NakedPairs
    Sudoku::Strategy::HiddenPairs
);

sub name {
    return 'Digit Forcing Chains';
}

sub apply {
    my ( $self, $grid ) = @_;

    for my $cell (@{ $grid->cells }) {
        next if $cell->value;

        my @candidates = grep { $cell->possibilities->[$_] } 1 .. 9;
        # The first forcing-chain implementation is intentionally bounded to
        # bivalue premises. This keeps the search human-scaled and prevents
        # pathological branching on broad, underconstrained grids.
        next unless @candidates == 2;

        for my $value (@candidates) {
            my $on  = $self->_run_branch($grid, $cell, $value, 'on');
            my $off = $self->_run_branch($grid, $cell, $value, 'off');

            my $deduction = $self->_compare_branches(
                $grid, $cell, $value, $on, $off,
            );
            return ($deduction) if $deduction;
        }
    }

    return;
}

sub _run_branch {
    my ( $self, $grid, $cell, $value, $assumption ) = @_;

    my %args = (
        grid       => $grid,
        row        => $cell->row,
        column     => $cell->column,
        value      => $value,
        assumption => $assumption,
        max_steps  => $self->{max_branch_steps} // MAX_BRANCH_STEPS,
    );
    $args{strategy_classes} = $self->{strategy_classes}
        ? [ @{ $self->{strategy_classes} } ]
        : [ @DEFAULT_PROPAGATION_STRATEGIES ];

    return Sudoku::Hypothetical->new(%args)->run;
}

sub _compare_branches {
    my ( $self, $grid, $source, $value, $on, $off ) = @_;

    my $on_bad  = $on->has_contradiction  ? 1 : 0;
    my $off_bad = $off->has_contradiction ? 1 : 0;

    # If both assumptions contradict, the source state is already inconsistent;
    # a forcing strategy must not invent a deduction from it.
    return if $on_bad && $off_bad;

    if ($on_bad) {
        return Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'remove_candidate',
            cell     => $source,
            value    => $value,
            reason   => sprintf(
                'Assuming %s=%d produces a contradiction, so candidate %d is false.',
                _cell_label($source), $value, $value,
            ),
            explanation => sprintf(
                'Remove candidate %d from %s. The ON branch contradicts after %d '
                . 'propagated step%s: %s',
                $value,
                _cell_label($source),
                $on->steps,
                $on->steps == 1 ? q{} : 's',
                _contradiction_text($on),
            ),
        );
    }

    if ($off_bad) {
        return Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'set_value',
            cell     => $source,
            value    => $value,
            reason   => sprintf(
                'Assuming %s is not %d produces a contradiction, so %s must be %d.',
                _cell_label($source), $value, _cell_label($source), $value,
            ),
            explanation => sprintf(
                'Set %s to %d. The OFF branch contradicts after %d propagated '
                . 'step%s: %s',
                _cell_label($source),
                $value,
                $off->steps,
                $off->steps == 1 ? q{} : 's',
                _contradiction_text($off),
            ),
        );
    }

    # Prefer a common placement over its implied candidate removals.
    for my $index (0 .. 80) {
        my $original = $grid->cells->[$index];
        next if $original->value;

        my $on_cell  = $on->grid->cells->[$index];
        my $off_cell = $off->grid->cells->[$index];
        next unless $on_cell->value;
        next unless $off_cell->value;
        next unless $on_cell->value == $off_cell->value;

        my $forced_value = $on_cell->value;
        return Sudoku::Deduction->new(
            strategy => $self->name,
            action   => 'set_value',
            cell     => $original,
            value    => $forced_value,
            cells    => [$source, $original],
            reason   => sprintf(
                'Whether %s is %d or is not %d, propagation sets %s=%d.',
                _cell_label($source), $value, $value,
                _cell_label($original), $forced_value,
            ),
            explanation => sprintf(
                'Set %s to %d. Both branches of candidate %d in %s reach the '
                . 'same placement (ON: %d steps; OFF: %d steps).',
                _cell_label($original), $forced_value,
                $value, _cell_label($source),
                $on->steps, $off->steps,
            ),
        );
    }

    for my $index (0 .. 80) {
        my $original = $grid->cells->[$index];
        next if $original->value;

        for my $candidate (1 .. 9) {
            next unless $original->possibilities->[$candidate];
            next unless _candidate_is_false($on->grid->cells->[$index], $candidate);
            next unless _candidate_is_false($off->grid->cells->[$index], $candidate);

            return Sudoku::Deduction->new(
                strategy => $self->name,
                action   => 'remove_candidate',
                cell     => $original,
                value    => $candidate,
                cells    => [$source, $original],
                reason   => sprintf(
                    'Whether %s is %d or is not %d, candidate %d is eliminated from %s.',
                    _cell_label($source), $value, $value,
                    $candidate, _cell_label($original),
                ),
                explanation => sprintf(
                    'Remove candidate %d from %s. Both branches of candidate %d '
                    . 'in %s eliminate it (ON: %d steps; OFF: %d steps).',
                    $candidate, _cell_label($original),
                    $value, _cell_label($source),
                    $on->steps, $off->steps,
                ),
            );
        }
    }

    return;
}

sub _candidate_is_false {
    my ( $cell, $candidate ) = @_;

    return $cell->value != $candidate if $cell->value;
    return !$cell->possibilities->[$candidate];
}

sub _contradiction_text {
    my ($result) = @_;

    return 'the branch is contradictory' unless $result->has_contradiction;
    return $result->contradiction->message;
}

sub _cell_label {
    my ($cell) = @_;
    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

1;
