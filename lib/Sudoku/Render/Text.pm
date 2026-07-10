package Sudoku::Render::Text;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    $args{mode} //= 'normal';
    return bless \%args, $class;
}

sub mode {
    my ($self, $mode) = @_;
    $self->{mode} = $mode if @_ > 1;
    return $self->{mode};
}

sub pass_start {
    my ($self, $pass) = @_;

    return sprintf "Pass %d\n%s\n", $pass, '-' x (5 + length($pass));
}

sub pass_end {
    my ($self, $pass, $progress) = @_;

    return sprintf "End Pass %d: %s\n\n",
        $pass,
        $progress ? "applied $progress deduction" . ($progress == 1 ? q{} : 's') : 'no progress';
}

sub strategy_result {
    my ($self, $strategy_name, $count) = @_;

    return sprintf "    %s: %s\n",
        $strategy_name,
        $count ? "applied $count deduction" . ($count == 1 ? q{} : 's') : 'no deductions';
}

sub restart_notice {
    return "    Restarting from Naked Singles.\n";
}

sub deduction {
    my ($self, $deduction) = @_;

    my $title = $self->deduction_title($deduction);
    my @lines = ($title);

    if (($deduction->action // q{}) eq 'set_value') {
        push @lines, sprintf '    Set %s = %s',
            $self->deduction_location($deduction),
            $deduction->has_value ? $deduction->value : '?';
    }
    elsif (($deduction->action // q{}) eq 'remove_candidate') {
        push @lines, sprintf '    Remove candidate %s from %s',
            $deduction->has_value ? $deduction->value : '?',
            $self->deduction_location($deduction);
    }
    else {
        push @lines, sprintf '    Action: %s', $deduction->action // 'unknown';
    }

    push @lines, '    Why: ' . $deduction->reason
        if length($deduction->reason // q{});

    if (length($deduction->explanation // q{})
        && $deduction->explanation ne $deduction->reason) {
        push @lines, '    Detail: ' . $deduction->explanation;
    }

    return join("\n", @lines) . "\n";
}

sub deduction_title {
    my ($self, $deduction) = @_;

    if (($deduction->strategy // q{}) eq 'Hidden Singles') {
        my $unit = $deduction->can('unit_label') ? $deduction->unit_label : q{};
        return length($unit) ? "Hidden Single in $unit:" : 'Hidden Single:';
    }

    return ($deduction->strategy // 'Deduction') . ':';
}

sub deduction_location {
    my ($self, $deduction) = @_;

    return $deduction->location if $deduction->can('location') && $deduction->location;
    return 'unknown cell';
}

sub debug_grid_header {
    my ($self, $deduction_number) = @_;

    return sprintf "Grid after deduction %d:\n", $deduction_number;
}

sub final_status {
    my ($self, $solver, $grid) = @_;

    my $deductions = $solver->deduction_count;
    my $difficulty = $solver->difficulty;

    if ($solver->has_contradiction) {
        return join q{},
            "Contradiction\n",
            "-------------\n",
            $solver->contradiction->summary . "\n",
            sprintf("Solved cells: %d / 81\n", $grid->solved),
            sprintf("Deductions applied: %d\n", $deductions),
            sprintf("Difficulty so far: %s (method v%s)\n",
                $difficulty->label, $difficulty->rating_version);
    }

    if ($grid->solved == 81) {
        my $solution = join q{}, map { $_->value } @{ $grid->cells };
        return join q{},
            "Solved\n",
            "------\n",
            sprintf("Solved all 81 cells in %d deduction%s.\n",
                $deductions, $deductions == 1 ? q{} : 's'),
            sprintf("Difficulty: %s (method v%s)\n",
                $difficulty->label, $difficulty->rating_version),
            "Solution: $solution\n";
    }

    return join q{},
        "Stalled\n",
        "-------\n",
        sprintf("Solved cells: %d / 81\n", $grid->solved),
        sprintf("Remaining cells: %d\n", 81 - $grid->solved),
        sprintf("Deductions applied: %d\n", $deductions),
        sprintf("Difficulty so far: %s (method v%s)\n",
            $difficulty->label, $difficulty->rating_version),
        "No registered strategy can make further progress.\n";
}

1;
