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

    my $reason = $deduction->explanation || $deduction->reason;
    push @lines, "    Reason: $reason" if $reason;

    return join("\n", @lines) . "\n";
}

sub deduction_title {
    my ($self, $deduction) = @_;

    if (($deduction->strategy // q{}) eq 'Hidden Singles') {
        if ($deduction->reason =~ /Hidden in Box/) {
            my $box = $deduction->has_cell ? $deduction->cell->box + 1 : undef;
            return defined $box ? "Hidden Single in Box $box:" : 'Hidden Single:';
        }

        if ($deduction->reason =~ /Hidden in Row/) {
            my $row = $deduction->has_cell ? $deduction->cell->row + 1 : undef;
            return defined $row ? "Hidden Single in Row $row:" : 'Hidden Single:';
        }

        if ($deduction->reason =~ /Hidden in Col/) {
            my $column = $deduction->has_cell ? $deduction->cell->column + 1 : undef;
            return defined $column ? "Hidden Single in Column $column:" : 'Hidden Single:';
        }

        return 'Hidden Single:';
    }

    return ($deduction->strategy // 'Deduction') . ':';
}

sub deduction_location {
    my ($self, $deduction) = @_;

    return $deduction->location if $deduction->can('location') && $deduction->location;
    return 'unknown cell';
}

sub final_status {
    my ($self, $solver, $grid) = @_;

    if ($solver->has_contradiction) {
        return 'Contradiction detected: ' . $solver->contradiction->summary . "\n";
    }

    if ($grid->solved == 81) {
        my $solution = join q{}, map { $_->value } @{ $grid->cells };
        return "We have solved this puzzle.  Final solution is:\n$solution\n";
    }

    return sprintf "We were able to determine %d cells.\n", $grid->solved;
}

1;
