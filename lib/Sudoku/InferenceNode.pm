package Sudoku::InferenceNode;

use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);

sub new {
    my ( $class, %args ) = @_;

    my $digit = $args{digit};
    my $cells = $args{cells};

    die "InferenceNode requires digit 1..9\n"
        unless defined $digit && $digit =~ /^[1-9]$/;
    die "InferenceNode requires a non-empty cells array reference\n"
        unless ref($cells) eq 'ARRAY' && @{$cells};

    my %seen;
    my @ordered = sort {
        $a->row <=> $b->row || $a->column <=> $b->column
    } grep {
        blessed($_) && $_->can('row') && $_->can('column')
            && !$seen{ refaddr($_) }++
    } @{$cells};

    die "InferenceNode cells must be cell-like objects\n"
        unless @ordered == @{$cells};

    return bless {
        digit => 0 + $digit,
        cells => \@ordered,
    }, $class;
}

sub digit {
    return $_[0]->{digit};
}

sub cells {
    return $_[0]->{cells};
}

sub is_group {
    return @{ $_[0]->{cells} } > 1 ? 1 : 0;
}

sub key {
    my ($self) = @_;
    return join q{:}, $self->digit,
        join q{,}, map { join q{.}, $_->row, $_->column } @{ $self->cells };
}

sub label {
    my ($self) = @_;
    my @labels = map {
        sprintf 'R%dC%d', $_->row + 1, $_->column + 1
    } @{ $self->cells };

    my $location = @labels == 1
        ? $labels[0]
        : '{' . join(q{,}, @labels) . '}';

    return sprintf '%s(%d)', $location, $self->digit;
}

sub contains_cell {
    my ( $self, $cell ) = @_;
    return scalar grep { $_ == $cell } @{ $self->cells };
}

sub overlaps {
    my ( $self, $other ) = @_;
    my %cells = map { refaddr($_) => 1 } @{ $self->cells };
    return scalar grep { $cells{ refaddr($_) } } @{ $other->cells };
}

1;
