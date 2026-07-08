package Sudoku::Difficulty;

use strict;
use warnings;

use Moose;
use Scalar::Util qw(blessed);

use Sudoku::Statistics;

=head1 NAME

Sudoku::Difficulty - Versioned difficulty rating for SudokuSolver statistics

=head1 DESCRIPTION

Difficulty ratings are interpretations of solve statistics, not permanent facts
about a puzzle.  Each rating records the rating-method version and the
statistics snapshot used to derive it so future rating methods can re-evaluate
old solves without ambiguity.

=cut

our $RATING_VERSION = '1.0';

my %STRATEGY_SCORE = (
    'Naked Singles'       => 1,
    'Hidden Singles'      => 2,
    'Pointing / Claiming' => 3,
    'Naked Pairs'         => 4,
    'Hidden Pairs'        => 4,
    'X-Wing'              => 5,
    'Remote Pairs'        => 6,
);

my %SCORE_LABEL = (
    0 => 'Unrated',
    1 => 'Trivial',
    2 => 'Easy',
    3 => 'Medium',
    4 => 'Hard',
    5 => 'Expert',
    6 => 'Master',
);

has 'rating_version' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { $RATING_VERSION },
);

has 'label' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'score' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'highest_strategy' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    predicate => 'has_highest_strategy',
);

has 'statistics_snapshot' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

sub from_solver {
    my ( $class, $solver ) = @_;

    die "from_solver requires an object with statistics()\n"
        unless blessed($solver) && $solver->can('statistics');

    return $class->from_statistics( $solver->statistics );
}

sub from_statistics {
    my ( $class, $statistics ) = @_;

    die "from_statistics requires a Sudoku::Statistics object\n"
        unless blessed($statistics) && $statistics->isa('Sudoku::Statistics');

    my $highest_strategy = $statistics->highest_strategy;
    my $score = defined $highest_strategy
        ? ( $STRATEGY_SCORE{$highest_strategy} // 0 )
        : 0;

    my %args = (
        label               => $SCORE_LABEL{$score} // 'Unknown',
        score               => $score,
        statistics_snapshot => $statistics->as_hash,
    );
    $args{highest_strategy} = $highest_strategy
        if defined $highest_strategy;

    return $class->new(%args);
}

sub strategy_score {
    my ( $self, $strategy ) = @_;

    return $STRATEGY_SCORE{$strategy} // 0;
}

sub summary {
    my ($self) = @_;

    my $strategy = $self->highest_strategy // 'none';

    return sprintf(
        '%s (difficulty v%s, score %d, highest strategy: %s)',
        $self->label,
        $self->rating_version,
        $self->score,
        $strategy,
    );
}

sub as_hash {
    my ($self) = @_;

    return {
        rating_version     => $self->rating_version,
        label              => $self->label,
        score              => $self->score,
        highest_strategy   => $self->highest_strategy,
        statistics_snapshot => $self->statistics_snapshot,
    };
}

__PACKAGE__->meta->make_immutable;

1;
