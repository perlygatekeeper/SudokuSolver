package Solver;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Types;
use Cell;
use Grid;
use Scalar::Util qw(blessed);
use Sudoku::Deduction;
use Sudoku::Contradiction;
use Sudoku::Strategy;
use Sudoku::Statistics;
use Sudoku::Explain;

has 'default_puzzle_file' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'Puzzles/sudoku17-first50.txt',
);




has 'status' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'ready',
);

has 'contradiction' => (
  isa       => 'Maybe[Sudoku::Contradiction]',
  is        => 'rw',
  predicate => 'has_contradiction',
  clearer   => 'clear_contradiction',
);

sub reset_status {
  my ($self) = @_;

  $self->status('ready');
  $self->clear_contradiction;

  return $self;
}

sub check_contradiction {
  my ( $self, $grid ) = @_;

  die "check_contradiction requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  my $contradiction = $self->_find_contradiction($grid);

  if ($contradiction) {
    $self->contradiction($contradiction);
    $self->status('contradiction');
    return $contradiction;
  }

  return;
}

sub _find_contradiction {
  my ( $self, $grid ) = @_;

  for my $cell ( @{ $grid->cells } ) {
    next if $cell->value;
    next if $cell->possibilities->[0] > 0;

    return Sudoku::Contradiction->new(
      kind        => 'zero_candidates',
      message     => 'Unsolved cell has no remaining candidates.',
      cell        => $cell,
      explanation => sprintf(
        'Cell R%dC%d has no remaining candidates.',
        $cell->row + 1,
        $cell->column + 1,
      ),
    );
  }

  for my $unit_spec (
    [ row    => $grid->rows ],
    [ column => $grid->columns ],
    [ box    => $grid->boxes ],
  ) {
    my ( $unit_name, $units ) = @{$unit_spec};

    for my $index ( 0 .. $#{$units} ) {
      my %seen;

      for my $cell ( @{ $units->[$index] } ) {
        my $value = $cell->value;
        next unless $value;

        if ( my $first = $seen{$value} ) {
          return Sudoku::Contradiction->new(
            kind        => 'duplicate_value',
            message     => sprintf(
              'Duplicate value %d found in %s %d.',
              $value,
              $unit_name,
              $index + 1,
            ),
            cell        => $cell,
            cells       => [ $first, $cell ],
            unit        => sprintf('%s %d', $unit_name, $index + 1),
            value       => $value,
            explanation => sprintf(
              'Value %d appears more than once in %s %d.',
              $value,
              $unit_name,
              $index + 1,
            ),
          );
        }

        $seen{$value} = $cell;
      }
    }
  }

  return;
}

has 'strategy_classes' => (
  isa     => 'ArrayRef[Str]',
  is      => 'rw',
  default => sub { [ Sudoku::Strategy->ordered_strategy_classes ] },
);

sub strategies {
  my ($self) = @_;

  return map { $_->new } @{ $self->strategy_classes };
}

sub strategy_names {
  my ($self) = @_;

  return map { $_->name } $self->strategies;
}

has 'deductions' => (
  isa     => 'ArrayRef[Sudoku::Deduction]',
  is      => 'rw',
  default => sub { [] },
);

sub record_deduction {
  my ( $self, $deduction ) = @_;

  die "record_deduction requires a Sudoku::Deduction object
"
    unless blessed($deduction) && $deduction->isa('Sudoku::Deduction');

  push @{ $self->deductions }, $deduction;

  return $deduction;
}

sub clear_deductions {
  my ($self) = @_;

  $self->deductions([]);

  return $self;
}

sub deduction_count {
  my ($self) = @_;

  return scalar @{ $self->deductions };
}

sub statistics {
  my ($self) = @_;

  return Sudoku::Statistics->from_solver($self);
}

sub explain_deduction {
  my ( $self, $deduction ) = @_;

  return Sudoku::Explain->new->explain_deduction($deduction);
}

sub explain_next {
  my ( $self, $grid ) = @_;

  my $deduction = $self->hint($grid);
  return unless $deduction;

  return $self->explain_deduction($deduction);
}

sub apply_deductions {
  my ( $self, $grid, @deductions ) = @_;

  my $progress = 0;

  for my $deduction (@deductions) {
    next unless $deduction;
    $progress += $self->apply_deduction( $grid, $deduction );
  }

  return $progress;
}

sub apply_deduction {
  my ( $self, $grid, $deduction ) = @_;

  die "apply_deduction requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  die "apply_deduction requires a Sudoku::Deduction object\n"
    unless blessed($deduction) && $deduction->isa('Sudoku::Deduction');

  if ( $deduction->action eq 'set_value' ) {
    return $self->_apply_set_value_deduction( $grid, $deduction );
  }

  if ( $deduction->action eq 'remove_candidate' ) {
    return $self->_apply_remove_candidate_deduction( $grid, $deduction );
  }

  die "Unknown deduction action: " . $deduction->action . "\n";
}

sub _apply_set_value_deduction {
  my ( $self, $grid, $deduction ) = @_;

  my $cell = $deduction->has_cell
    ? $deduction->cell
    : $grid->cell_from_row_column( $deduction->row, $deduction->column );

  return 0 if $cell->value;

  my $value = $deduction->value;

  $grid->solved( 1 + $grid->solved );
  $cell->value($value);
  $cell->possibilities([ (0) x 10 ]);
  $grid->remove_my_solution_from_my_mates($cell);

  if ( $deduction->reason =~ /^Hidden in / ) {
    printf "%s Setting cell ( %d, %d, %d ) to %d\n",
      $deduction->reason,
      ( $cell->row + 1 ),
      ( $cell->column + 1 ),
      ( $cell->box + 1 ),
      $value;
  }

  $self->record_deduction($deduction);
  $self->check_contradiction($grid);

  return 1;
}

sub _apply_remove_candidate_deduction {
  my ( $self, $grid, $deduction ) = @_;

  my $cell = $deduction->has_cell
    ? $deduction->cell
    : $grid->cell_from_row_column( $deduction->row, $deduction->column );

  return 0 if $cell->value;
  return 0 unless $deduction->has_value;

  my $value = $deduction->value;
  return 0 unless $cell->possibilities->[$value];

  my $removed = $cell->remove_possibility($value);

  print $deduction->reason . "\n" if $removed && $deduction->reason;

  if ($removed) {
    $self->record_deduction($deduction);
    $self->check_contradiction($grid);
  }

  return $removed ? 1 : 0;
}

sub normalize_puzzle_string {
  my ( $self, $puzzle_string ) = @_;

  $puzzle_string =~ s/\s+//g;
  $puzzle_string =~ s/[^1-9]/0/g;

  die "Puzzle string must contain exactly 81 digits or (0's, dots, dashes, or underscores for empty cells)\n"
    unless length($puzzle_string) == 81;

  return $puzzle_string;
}

sub puzzle_strings_from_file {
  my ( $self, $puzzle_file ) = @_;

  open my $puzzle_fh, '<', $puzzle_file
      or die "Could not open '$puzzle_file': $!";

  my @lines;
  while ( my $line = <$puzzle_fh> ) {
    chomp $line;
    $line =~ s/#.*$//;     # strip end-of-line comments
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next unless length $line;
    push @lines, $line;
  }
  close $puzzle_fh;

  die "No puzzle strings found in '$puzzle_file'\n" unless @lines;

  if ( @lines == 9 ) {
    my @normalized_rows = map { $self->normalize_puzzle_row($_) } @lines;

    if ( ! grep { length($_) != 9 } @normalized_rows ) {
      return join '', @normalized_rows;
    }
  }

  return map { $self->normalize_puzzle_string($_) } @lines;
}

sub normalize_puzzle_row {
  my ( $self, $row_string ) = @_;

  $row_string =~ s/\s+//g;
  $row_string =~ s/[^1-9]/0/g;

  return $row_string;
}

sub puzzle_string_from_options {
  my ( $self, %options ) = @_;

  if ( defined $options{puzzle_string} ) {
    return $self->normalize_puzzle_string( $options{puzzle_string} );
  }

  my $puzzle_file  = $options{puzzle_file} // $self->default_puzzle_file;
  my $puzzle_index = $options{puzzle_index} // 1;

  my @puzzle_strings = $self->puzzle_strings_from_file($puzzle_file);

  die "Puzzle number must be between 1 and " . scalar(@puzzle_strings) . "\n"
    if $puzzle_index < 1 || $puzzle_index > @puzzle_strings;

  return $puzzle_strings[ $puzzle_index - 1 ];
}

sub hint {
  my ( $self, $grid ) = @_;

  die "hint requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  return if $grid->solved > 80;
  return if $self->check_contradiction($grid);

  for my $strategy ( $self->strategies ) {
    my @deductions = $strategy->apply($grid);

    for my $deduction (@deductions) {
      next unless $deduction;
      return $deduction;
    }
  }

  return;
}

sub step {
  my ( $self, $grid ) = @_;

  die "step requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  my $deduction = $self->hint($grid);
  return unless $deduction;

  my $progress = $self->apply_deduction( $grid, $deduction );

  return $progress ? $deduction : undef;
}

sub run_strategy {
  my ( $self, $grid, $strategy ) = @_;

  die "run_strategy requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  die "run_strategy requires a strategy object with apply()\n"
    unless blessed($strategy) && $strategy->can('apply');

  my $total_progress = 0;

  while ( $grid->solved <= 80 and not $self->has_contradiction ) {
    my @deductions = $strategy->apply($grid);
    my $progress   = $self->apply_deductions( $grid, @deductions );

    last unless $progress;

    print "So far we filled this many cells: " . $grid->solved . "\n";
    $grid->big_print;

    $total_progress += $progress;

    my $name = $strategy->can('name') ? lc $strategy->name : 'strategy';
    print "---- end $name processing ----\n\n";
  }

  return $total_progress;
}

sub run {
  my ( $self, %options ) = @_;

  my $puzzle_string = $self->puzzle_string_from_options(%options);

  print "puzzle_string: $puzzle_string\n";

  my $puzzle = Grid->new;
  $puzzle->load_from_string($puzzle_string);

  $self->reset_status;
  $self->check_contradiction($puzzle);

  my($pass_progress) = 1;
  my($pass) = 0;

  while ( $puzzle->solved <= 80 and $pass_progress and not $self->has_contradiction ) {
    print "==== Pass " . ++$pass . " ====\n";
    $pass_progress = 0;
    $puzzle->big_print;

    for my $strategy ( $self->strategies ) {
      last if $puzzle->solved > 80;

      my $strategy_progress = $self->run_strategy( $puzzle, $strategy );
      $pass_progress += $strategy_progress;

      # Preserve the legacy solving hierarchy: after any successful strategy,
      # restart the next pass from the easiest strategy rather than continuing
      # on to harder strategies in the same pass.
      last if $strategy_progress;
    }

    print "==== End Pass " . $pass . " (progress is $pass_progress) ====\n";

  }

  if ( $self->has_contradiction ) {
    print "Contradiction detected: " . $self->contradiction->summary . "\n";
  } elsif ( $puzzle->solved == 81 ) {
    print "We have solved this puzzle.  Final solution is:\n";
    print $_->value foreach ( @{$puzzle->cells} );
    print "\n";
  } else {
    printf "We were able to determine %d cells.\n", $puzzle->solved;
    $puzzle->big_print;
  }

  return $puzzle;
}

1;
