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
use Sudoku::Strategy;

has 'default_puzzle_file' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'Puzzles/sudoku17-first50.txt',
);



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

  $self->record_deduction($deduction) if $removed;

  return $removed ? 1 : 0;
}

sub normalize_puzzle_string {
  my ( $self, $puzzle_string ) = @_;

  $puzzle_string =~ s/\s+//g;
  $puzzle_string =~ tr/./0/;

  die "Puzzle string must contain exactly 81 digits or dots\n"
    unless $puzzle_string =~ /^\d{81}$/;

  return $puzzle_string;
}

sub puzzle_strings_from_file {
  my ( $self, $puzzle_file ) = @_;

  open my $puzzle_fh, '<', $puzzle_file
      or die "Could not open '$puzzle_file': $!";

  my @puzzle_strings;
  while ( my $line = <$puzzle_fh> ) {
    next if ( $line =~ /^\s*$|^\s*#/ ); # skip white, blank and commented lines.
    chomp $line;
    $line =~ s/\s+//g;
    next unless length $line;
    push @puzzle_strings, $self->normalize_puzzle_string($line);
  }
  close $puzzle_fh;

  die "No puzzle strings found in '$puzzle_file'\n" unless @puzzle_strings;

  return @puzzle_strings;
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

sub run_strategy {
  my ( $self, $grid, $strategy ) = @_;

  die "run_strategy requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  die "run_strategy requires a strategy object with apply()\n"
    unless blessed($strategy) && $strategy->can('apply');

  my $total_progress = 0;

  while ( $grid->solved <= 80 ) {
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

  my($pass_progress) = 1;
  my($pass) = 0;

  while ( $puzzle->solved <= 80 and $pass_progress ) {
    print "==== Pass " . ++$pass . " ====\n";
    $pass_progress = 0;
    $puzzle->big_print;

    for my $strategy ( $self->strategies ) {
      last if $puzzle->solved > 80;
      $pass_progress += $self->run_strategy( $puzzle, $strategy );
    }

    print "==== End Pass " . $pass . " (progress is $pass_progress) ====\n";

  }

  if ( $puzzle->solved == 81 ) {
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
