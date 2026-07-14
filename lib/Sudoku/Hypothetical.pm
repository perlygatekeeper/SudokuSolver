package Sudoku::Hypothetical;

use strict;
use warnings;

use Moose;
use Grid;
use Solver;
use Sudoku::Contradiction;
use Sudoku::Deduction;
use Sudoku::Hypothetical::Result;
use Sudoku::Strategy;

has 'grid' => (
    is       => 'ro',
    isa      => 'Grid',
    required => 1,
);

has 'row' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'column' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'value' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'assumption' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'on',
);

has 'max_steps' => (
    is      => 'ro',
    isa     => 'Int',
    default => 500,
);

has 'strategy_classes' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub {
        return [
            grep { $_ !~ /(?:Forcing|Nishio|Hypothetical)/ }
                Sudoku::Strategy->ordered_strategy_classes
        ];
    },
);

sub BUILD {
    my ($self) = @_;

    die "row must be between 0 and 8\n"
        unless $self->row >= 0 && $self->row <= 8;
    die "column must be between 0 and 8\n"
        unless $self->column >= 0 && $self->column <= 8;
    die "value must be between 1 and 9\n"
        unless $self->value >= 1 && $self->value <= 9;
    die "assumption must be 'on' or 'off'\n"
        unless $self->assumption eq 'on' || $self->assumption eq 'off';
    die "max_steps must be positive\n"
        unless $self->max_steps > 0;

    return;
}

sub clone_grid {
    my ($self) = @_;

    my $source = $self->grid;
    my $clone  = Grid->new;

    $clone->load_from_string($source->as_puzzle_string);
    $clone->solved($source->solved);

    for my $index (0 .. 80) {
        my $source_cell = $source->cells->[$index];
        my $clone_cell  = $clone->cells->[$index];

        $clone_cell->given($source_cell->given);
        $clone_cell->value($source_cell->value);
        $clone_cell->possibilities([ @{ $source_cell->possibilities } ]);
    }

    $clone->notes($source->notes) if defined $source->notes;
    $clone->difficulty($source->difficulty) if defined $source->difficulty;

    return $clone;
}

sub run {
    my ($self) = @_;

    my $branch = $self->clone_grid;
    my $solver = Solver->new(
        strategy_classes => [ @{ $self->strategy_classes } ],
        output_mode      => 'quiet',
    );

    $solver->reset_status;
    $solver->check_contradiction($branch);

    my $assumption = {
        row    => $self->row,
        column => $self->column,
        value  => $self->value,
        state  => $self->assumption,
    };

    my @history = ({
        kind       => 'assumption',
        strategy   => 'Hypothetical Assumption',
        assumption => { %{$assumption} },
    });
    my $assumption_deduction;

    if (!$solver->has_contradiction) {
        my $contradiction;
        ($assumption_deduction, $contradiction) =
            $self->_apply_assumption($solver, $branch);

        $history[0]{deduction} = $assumption_deduction
            if $assumption_deduction;

        if ($contradiction) {
            $solver->contradiction($contradiction);
            $solver->status('contradiction');
        }
    }

    my $assumption_count = $solver->deduction_count;
    my $propagation = $solver->propagate(
        $branch,
        max_steps => $self->max_steps,
    );

    push @history, @{ $propagation->{history} };

    my @deductions = @{ $solver->deductions };
    splice @deductions, 0, $assumption_count if $assumption_count;

    my %result_args = (
        status     => $propagation->{status},
        assumption => $assumption,
        grid       => $branch,
        steps      => $propagation->{steps},
        deductions => \@deductions,
        history    => \@history,
    );

    $result_args{contradiction} = $solver->contradiction
        if $solver->has_contradiction && $solver->contradiction;

    return Sudoku::Hypothetical::Result->new(%result_args);
}

sub _apply_assumption {
    my ($self, $solver, $grid) = @_;

    my $cell = $grid->cell_from_row_column($self->row, $self->column);
    my $value = $self->value;

    if ($self->assumption eq 'on') {
        if ($cell->value) {
            return if $cell->value == $value;

            return (undef, $self->_contradiction(
                $cell,
                'assumption_conflicts_with_value',
                sprintf(
                    'Assuming R%dC%d=%d conflicts with its existing value %d.',
                    $self->row + 1,
                    $self->column + 1,
                    $value,
                    $cell->value,
                ),
            ));
        }

        unless ($cell->possibilities->[$value]) {
            return (undef, $self->_contradiction(
                $cell,
                'assumption_candidate_absent',
                sprintf(
                    'Candidate %d is not available in R%dC%d.',
                    $value,
                    $self->row + 1,
                    $self->column + 1,
                ),
            ));
        }

        my $deduction = Sudoku::Deduction->new(
            strategy    => 'Hypothetical Assumption',
            action      => 'set_value',
            cell        => $cell,
            value       => $value,
            reason      => 'Temporary ON assumption.',
            explanation => sprintf(
                'Temporarily assume R%dC%d is %d.',
                $self->row + 1,
                $self->column + 1,
                $value,
            ),
        );

        $solver->apply_deduction($grid, $deduction);
        return ($deduction, undef);
    }

    if ($cell->value) {
        return if $cell->value != $value;

        return (undef, $self->_contradiction(
            $cell,
            'assumption_excludes_value',
            sprintf(
                'Assuming R%dC%d is not %d conflicts with its existing value.',
                $self->row + 1,
                $self->column + 1,
                $value,
            ),
        ));
    }

    return unless $cell->possibilities->[$value];

    my $deduction = Sudoku::Deduction->new(
        strategy    => 'Hypothetical Assumption',
        action      => 'remove_candidate',
        cell        => $cell,
        value       => $value,
        reason      => 'Temporary OFF assumption.',
        explanation => sprintf(
            'Temporarily assume R%dC%d is not %d.',
            $self->row + 1,
            $self->column + 1,
            $value,
        ),
    );

    $solver->apply_deduction($grid, $deduction);
    return ($deduction, undef);
}

sub _contradiction {
    my ($self, $cell, $kind, $message) = @_;

    return Sudoku::Contradiction->new(
        kind        => $kind,
        message     => $message,
        cell        => $cell,
        value       => $self->value,
        explanation => $message,
    );
}

__PACKAGE__->meta->make_immutable;

1;
