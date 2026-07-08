package Sudoku::Explain;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Sudoku::Deduction;

=head1 NAME

Sudoku::Explain - Format Sudoku deductions as human-readable explanations

=head1 DESCRIPTION

Sudoku::Explain is intentionally small.  Strategies are responsible for
producing structured Deduction objects; this module is responsible for turning
those deductions into user-facing text.

=cut

sub new {
  my ($class) = @_;

  return bless {}, $class;
}

sub explain_deduction {
  my ( $self, $deduction ) = @_;

  die "explain_deduction requires a Sudoku::Deduction object\n"
    unless blessed($deduction) && $deduction->isa('Sudoku::Deduction');

  return $deduction->explanation if length $deduction->explanation;

  my @parts;

  push @parts, $deduction->strategy;

  if ( $deduction->action eq 'set_value' ) {
    push @parts, 'sets';
    push @parts, $deduction->location if $deduction->has_cell_location;
    push @parts, 'to ' . $deduction->value if $deduction->has_value;
  }
  elsif ( $deduction->action eq 'remove_candidate' ) {
    push @parts, 'removes candidate';
    push @parts, $deduction->value if $deduction->has_value;
    push @parts, 'from';
    push @parts, $deduction->location if $deduction->has_cell_location;
  }
  else {
    push @parts, $deduction->action;
    push @parts, $deduction->location if $deduction->has_cell_location;
  }

  push @parts, q{-} if length $deduction->reason;
  push @parts, $deduction->reason if length $deduction->reason;

  return join q{ }, grep { defined && length } @parts;
}

1;
