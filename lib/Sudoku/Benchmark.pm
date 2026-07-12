package Sudoku::Benchmark;

use strict;
use warnings;

use Moose;
use Time::HiRes qw(time);
use File::Spec;

use Solver;
use Sudoku::Strategy;

=head1 NAME

Sudoku::Benchmark - Benchmark SudokuSolver against a puzzle collection

=head1 DESCRIPTION

Sudoku::Benchmark runs a puzzle file through the solver and records a concise,
presentation-neutral summary.  It is intended for release checks and for
tracking progress against canonical puzzle collections such as the first 50
17-clue puzzles.

=cut

has 'file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'results' => (
    is      => 'rw',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
);

sub run {
    my ($self) = @_;

    my $loader = Solver->new;
    my @puzzles = $loader->puzzle_strings_from_file( $self->file );

    my @results;
    my $index = 0;

    for my $puzzle_string (@puzzles) {
        ++$index;
        push @results, $self->_run_one( $index, $puzzle_string );
    }

    $self->results(\@results);

    return $self;
}

sub _run_one {
    my ( $self, $index, $puzzle_string ) = @_;

    my $solver = Solver->new;
    my $start  = time;
    my $grid;

    {
        open my $null, '>', File::Spec->devnull
            or die "Could not open null device: $!";
        local *STDOUT = $null;
        $grid = $solver->run( puzzle_string => $puzzle_string );
    }

    my $elapsed = time - $start;

    my $status = $solver->has_contradiction
        ? 'contradiction'
        : ( $grid->solved == 81 ? 'solved' : 'stalled' );

    my $difficulty = $solver->difficulty;
    my $statistics = $solver->statistics;

    return {
        index            => $index,
        status           => $status,
        solved_cells     => $grid->solved,
        deduction_count  => $solver->deduction_count,
        elapsed          => $elapsed,
        difficulty       => $difficulty->label,
        difficulty_score => $difficulty->score,
        highest_strategy => $difficulty->highest_strategy,
        strategy_contributions => $statistics->contribution_by_strategy,
    };
}

sub processed {
    my ($self) = @_;

    return scalar @{ $self->results };
}

sub solved {
    my ($self) = @_;

    return scalar grep { $_->{status} eq 'solved' } @{ $self->results };
}

sub stalled {
    my ($self) = @_;

    return scalar grep { $_->{status} eq 'stalled' } @{ $self->results };
}

sub contradictions {
    my ($self) = @_;

    return scalar grep { $_->{status} eq 'contradiction' } @{ $self->results };
}

sub unsolved_results {
    my ($self) = @_;

    return grep { $_->{status} ne 'solved' } @{ $self->results };
}

sub total_elapsed {
    my ($self) = @_;

    my $total = 0;
    $total += ($_->{elapsed} // 0) for @{ $self->results };

    return $total;
}

sub average_elapsed {
    my ($self) = @_;

    return 0 unless $self->processed;
    return $self->total_elapsed / $self->processed;
}

sub highest_strategy_usage {
    my ($self) = @_;

    my %counts;
    for my $result ( @{ $self->results } ) {
        next unless defined $result->{highest_strategy};
        $counts{ $result->{highest_strategy} }++;
    }

    return \%counts;
}


sub strategy_contributions {
    my ($self) = @_;

    my %totals = map {
        $_ => {
            puzzles_used          => 0,
            deductions            => 0,
            cells_solved          => 0,
            candidates_eliminated => 0,
        }
    } Sudoku::Strategy::ordered_strategy_names();

    for my $result ( @{ $self->results } ) {
        my $by_strategy = $result->{strategy_contributions} || {};

        for my $strategy ( keys %{$by_strategy} ) {
            my $source = $by_strategy->{$strategy};
            my $target = $totals{$strategy} ||= {
                puzzles_used          => 0,
                deductions            => 0,
                cells_solved          => 0,
                candidates_eliminated => 0,
            };

            $target->{puzzles_used}++ if $source->{deductions};
            $target->{deductions}            += $source->{deductions}            || 0;
            $target->{cells_solved}          += $source->{cells_solved}          || 0;
            $target->{candidates_eliminated} += $source->{candidates_eliminated} || 0;
        }
    }

    return \%totals;
}

sub summary_text {
    my ($self) = @_;

    my $usage = $self->highest_strategy_usage;
    my @lines = (
        'Canonical 17-Clue Benchmark',
        '===========================',
        '',
        'Benchmark file:',
        '    ' . $self->file,
        '',
        sprintf( 'Puzzles processed : %d', $self->processed ),
        sprintf( 'Solved            : %d', $self->solved ),
        sprintf( 'Stalled           : %d', $self->stalled ),
        sprintf( 'Contradictions    : %d', $self->contradictions ),
        '',
        sprintf( 'Average solve time: %.6f s', $self->average_elapsed ),
        sprintf( 'Total time        : %.6f s', $self->total_elapsed ),
    );

    if ( keys %{$usage} ) {
        push @lines, '', 'Highest strategy usage', '';
        for my $strategy ( sort keys %{$usage} ) {
            push @lines, sprintf( '    %-20s %5d', $strategy, $usage->{$strategy} );
        }
    }

    my $contributions = $self->strategy_contributions;
    push @lines,
        '',
        'Strategy contributions',
        '',
        '    Strategy                     Puzzles  Deductions  Cells  Eliminations',
        '    ---------------------------  -------  ----------  -----  ------------';

    for my $strategy ( Sudoku::Strategy::ordered_strategy_names() ) {
        my $entry = $contributions->{$strategy};
        push @lines, sprintf(
            '    %-23s  %7d  %10d  %5d  %12d',
            $strategy,
            $entry->{puzzles_used},
            $entry->{deductions},
            $entry->{cells_solved},
            $entry->{candidates_eliminated},
        );
    }

    my @unsolved = $self->unsolved_results;
    if (@unsolved) {
        push @lines, '', 'Unsolved puzzles', '';
        for my $result (@unsolved) {
            push @lines, sprintf(
                '   %04d  %-17s solved cells: %2d  difficulty: %s',
                ($result->{index}        // 0),
                ($result->{status}       // 'unknown'),
                ($result->{solved_cells} // 0),
                ($result->{difficulty}   // 'Unrated'),
            );
        }
    }

    return join( "\n", @lines ) . "\n";
}

__PACKAGE__->meta->make_immutable;

1;
