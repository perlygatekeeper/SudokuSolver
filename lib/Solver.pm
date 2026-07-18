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
use Sudoku::Difficulty;
use Sudoku::Explain;
use Sudoku::Render::Text;
use Sudoku::Render::EventLog;

has 'default_puzzle_file' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'Puzzles/Puzzle3.txt',
);

has 'debug' => (
  isa     => 'Bool',
  is      => 'rw',
  default => 0,
);

has 'trace_grid_after_deduction' => (
  isa     => 'Bool',
  is      => 'rw',
  default => 0,
);

has 'output_mode' => (
  isa     => 'Str',
  is      => 'rw',
  default => 'normal',
);

has 'renderer' => (
  isa     => 'Sudoku::Render::Text',
  is      => 'rw',
  default => sub { Sudoku::Render::Text->new },
);

has 'event_log' => (
  isa     => 'Sudoku::Render::EventLog',
  is      => 'ro',
  default => sub { Sudoku::Render::EventLog->new },
);

sub events {
  my ($self) = @_;
  return $self->event_log->events;
}

sub clear_events {
  my ($self) = @_;
  $self->event_log->clear;
  return $self;
}

sub record_event {
  my ( $self, $type, %data ) = @_;
  return $self->event_log->record( $type, %data );
}

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
    my $is_new = !$self->has_contradiction;
    $self->contradiction($contradiction);
    $self->status('contradiction');
    $self->record_event(
      'contradiction',
      kind        => $contradiction->kind,
      message     => $contradiction->message,
      location    => $contradiction->location,
      explanation => $contradiction->explanation,
    ) if $is_new;
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

has 'last_strategy_attempts' => (
  isa     => 'ArrayRef',
  is      => 'rw',
  default => sub { [] },
);

sub clear_strategy_attempts {
  my ($self) = @_;

  $self->last_strategy_attempts([]);

  return $self;
}

sub record_strategy_attempt {
  my ( $self, $strategy_name, $deduction_count ) = @_;

  push @{ $self->last_strategy_attempts }, {
    strategy => $strategy_name,
    count    => $deduction_count || 0,
  };

  return $self;
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

  my %event_data = (
    strategy    => $deduction->strategy,
    action      => $deduction->action,
    location    => $deduction->location,
    reason      => $deduction->reason,
    explanation => $deduction->explanation,
  );

  for my $field (qw(row column box unit_type unit_index value candidate)) {
    my $predicate = "has_$field";
    $event_data{$field} = $deduction->$field if $deduction->$predicate;
  }

  $self->record_event( 'deduction', %event_data );

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

sub difficulty {
  my ($self) = @_;

  return Sudoku::Difficulty->from_solver($self);
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

sub trace_deduction {
  my ( $self, $grid, $deduction ) = @_;

  return unless $self->trace_grid_after_deduction;

  print $self->renderer->debug_grid_header( $self->deduction_count );
  print $self->renderer->render_grid( $grid, format => 'candidates' );

  return $deduction;
}

sub emit_deduction {
  my ( $self, $deduction ) = @_;

  return if $self->output_mode eq 'quiet';
  return unless $self->output_mode =~ /^(explain|trace|debug)$/;

  print $self->renderer->deduction($deduction);

  return $deduction;
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

  $self->clear_strategy_attempts;

  return if $grid->solved > 80;
  return if $self->check_contradiction($grid);

  for my $strategy ( $self->strategies ) {
    my @deductions = grep { $_ } $strategy->apply($grid);

    $self->record_strategy_attempt( $strategy->name, scalar @deductions );

    return $deductions[0] if @deductions;
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

sub propagate {
  my ( $self, $grid, %options ) = @_;

  die "propagate requires a Grid object\n"
    unless blessed($grid) && $grid->isa('Grid');

  my $max_steps = $options{max_steps} // 500;
  die "max_steps must be a positive integer\n"
    unless $max_steps =~ /^\d+$/ && $max_steps > 0;

  my @history;
  my $steps = 0;

  $self->check_contradiction($grid) unless $self->has_contradiction;

  while (
    $grid->solved <= 80
      && !$self->has_contradiction
      && $steps < $max_steps
  ) {
    my $deduction = $self->step($grid);
    last unless $deduction;

    ++$steps;
    push @history, {
      kind      => 'deduction',
      step      => $steps,
      strategy  => $deduction->strategy,
      deduction => $deduction,
    };
  }

  my $status = $self->has_contradiction ? 'contradiction'
    : $grid->solved > 80                 ? 'solved'
    : $steps >= $max_steps               ? 'limit'
    :                                      'fixed_point';

  $self->status($status);

  return {
    status  => $status,
    steps   => $steps,
    history => \@history,
  };
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

    $total_progress += $progress;
  }

  return $total_progress;
}

sub run {
  my ( $self, %options ) = @_;

  $self->debug( $options{debug} ? 1 : 0 )
    if exists $options{debug};

  $self->trace_grid_after_deduction(
    $options{trace_grid_after_deduction} ? 1 : 0
  ) if exists $options{trace_grid_after_deduction};

  if ( exists $options{output_mode} && defined $options{output_mode} ) {
    $self->output_mode( $options{output_mode} );
    $self->renderer->mode( $options{output_mode} );
  }

  $self->clear_events;

  my $puzzle_string = $self->puzzle_string_from_options(%options);

  print "puzzle_string: $puzzle_string\n" if $self->debug;

  my $puzzle = Grid->new;
  $puzzle->load_from_string($puzzle_string);

  $self->reset_status;
  $self->check_contradiction($puzzle);

  my $pass = 0;

  while ( $puzzle->solved <= 80 and not $self->has_contradiction ) {
    ++$pass;
    $self->record_event( 'pass_started', pass => $pass );

    if ( $self->output_mode =~ /^(trace|debug)$/ ) {
      print $self->renderer->pass_start($pass);
      print $self->renderer->render_grid( $puzzle, format => 'candidates' )
        if $self->output_mode eq 'debug';
    }

    my $deduction = $self->step($puzzle);
    my $progress  = defined $deduction ? 1 : 0;

    for my $attempt ( @{ $self->last_strategy_attempts } ) {
      $self->record_event(
        'strategy_result',
        strategy => $attempt->{strategy},
        count    => 0 + $attempt->{count},
      );
    }

    if ( $self->output_mode =~ /^(trace|debug)$/ ) {
      for my $attempt ( @{ $self->last_strategy_attempts } ) {
        print $self->renderer->strategy_result(
          $attempt->{strategy},
          $attempt->{count},
        );
      }
    }

    if ($progress) {
      $self->emit_deduction($deduction);
      $self->trace_deduction( $puzzle, $deduction );

      $self->record_event( 'restart', from => 'Naked Singles' );

      print $self->renderer->restart_notice
        if $self->output_mode =~ /^(trace|debug)$/;
    }

    $self->record_event(
      'pass_finished',
      pass     => $pass,
      progress => $progress ? 1 : 0,
    );

    print $self->renderer->pass_end( $pass, $progress )
      if $self->output_mode =~ /^(trace|debug)$/;

    last unless $progress;
  }

  my $final_status = $self->has_contradiction ? 'contradiction'
    : $puzzle->solved == 81 ? 'solved'
    : 'stalled';
  $self->record_event(
    'final_status',
    status       => $final_status,
    solved_cells => 0 + $puzzle->solved,
    deductions   => 0 + $self->deduction_count,
  );

  print $self->renderer->final_status( $self, $puzzle )
    unless $self->output_mode eq 'quiet';

  print $self->renderer->render_grid( $puzzle, format => 'candidates' )
    if $puzzle->solved != 81 && $self->output_mode eq 'debug';

  return $puzzle;
}

1;
