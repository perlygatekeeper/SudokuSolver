package Grid;

use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;

use Types;
use Cell;
use Sudoku::Strategy::NakedSingles;
use Sudoku::Strategy::HiddenSingles;
use Sudoku::Strategy::PointingClaiming;
use Sudoku::Strategy::NakedPairs;
use Sudoku::Strategy::HiddenPairs;
use Sudoku::Strategy::XWing;
use Sudoku::Strategy::RemotePairs;

# use Data::Dumper;
# use Carp;

has 'difficulty'  => (isa => 'Difficulty', is => 'rw');
has 'notes'       => (isa => 'Str',        is => 'rw');
has 'solved'      => (isa => 'Int',        is => 'rw');
has 'rows'        => (isa => 'ArrayRef',   is => 'rw');
has 'columns'     => (isa => 'ArrayRef',   is => 'rw');
has 'boxes'       => (isa => 'ArrayRef',   is => 'rw');
has 'cells'       => (isa => 'ArrayRef',   is => 'rw');

# Methods
#
# Input of grid, setting each cell and establishing the rows, columns and boxes structures
# Output 'see below'
#
# given cell number, CELL, from 0 to 80 (0 will be reserved for string)
#
# ROW    = 1 + int(CELL/9) -> 1..9
# COLUMN = 1 + mod(CELL/9) -> 1..9
# BOX    = 1 + ( mod(CELL/9) / 3 ) + int(CELL/9) / 3 -> 1..9

sub load_from_string {
  my($self,$string) = @_;
  my($cell) = 0;
  $self->solved(0);
  $self->cells([]);
  $self->rows([[],[],[],[],[],[],[],[],[]]);
  $self->columns([[],[],[],[],[],[],[],[],[]]);
  $self->boxes([[],[],[],[],[],[],[],[],[]]);
  foreach ( split(//,$string) ) {
    s/[^1-9]/0/; # Change any character not 1, 2, 3, 4, 5, 6, 7, 8 OR 9  TO A  '0'  Such as underscores, dashes, periods or spaces
    my($col) = ( $cell  % 9 );
    my($row) = int( $cell / 9 );
    my($box) = int( ( $cell % 9 ) / 3 ) + 3 * int ( int( $cell / 9 ) / 3 );
    my ($new_cell) =  Cell->new;
    $new_cell->clue($_);
    $new_cell->row($row);    # print "Debug: " . $new_cell->row . " should be $row\n";
    $new_cell->column($col);
    $new_cell->box($box);

    $self->cells->[$cell++]      = $new_cell;
    push ( @{ $self->rows->[$row] },    $new_cell );
    push ( @{ $self->columns->[$col] }, $new_cell );
    push ( @{ $self->boxes->[$box] },   $new_cell );
  }
# print "We have populated the grid with the given clues,
# now we will remove the given's as possibilities from their rows, columns and boxes.\n";
  foreach ( grep { $_->value } @{$self->cells} ) {
    $self->solved( 1 + $self->solved );
    $self->remove_my_solution_from_my_mates($_);
  }
}

sub find_and_set_naked_singles {  # Naked Single: a cell with only one possible value left
  my $self = shift;

  my @deductions = Sudoku::Strategy::NakedSingles->new->apply($self);

  return $self->apply_deductions(@deductions);
}


sub apply_deductions {
  my ( $self, @deductions ) = @_;

  my $progress = 0;

  for my $deduction (@deductions) {
    next unless $deduction;
    $progress += $self->apply_deduction($deduction);
  }

  return $progress;
}

sub apply_deduction {
  my ( $self, $deduction ) = @_;

  if ( $deduction->action eq 'set_value' ) {
    return $self->_apply_set_value_deduction($deduction);
  }

  if ( $deduction->action eq 'remove_candidate' ) {
    return $self->_apply_remove_candidate_deduction($deduction);
  }

  die "Unknown deduction action: " . $deduction->action . "\n";
}

sub _apply_set_value_deduction {
  my ( $self, $deduction ) = @_;

  my $cell = $deduction->has_cell
    ? $deduction->cell
    : $self->cell_from_row_column( $deduction->row, $deduction->column );

  return 0 if $cell->value;

  my $value = $deduction->value;

  $self->solved( 1 + $self->solved );
  $cell->value($value);
  $cell->possibilities([ (0) x 10 ]);
  $self->remove_my_solution_from_my_mates($cell);

  if ( $deduction->reason =~ /^Hidden in / ) {
    printf "%s Setting cell ( %d, %d, %d ) to %d\n",
      $deduction->reason,
      ( $cell->row + 1 ),
      ( $cell->column + 1 ),
      ( $cell->box + 1 ),
      $value;
  }

  return 1;
}

sub _apply_remove_candidate_deduction {
  my ( $self, $deduction ) = @_;

  my $cell = $deduction->has_cell
    ? $deduction->cell
    : $self->cell_from_row_column( $deduction->row, $deduction->column );

  return 0 if $cell->value;
  return 0 unless $deduction->has_value;

  my $value = $deduction->value;
  return 0 unless $cell->possibilities->[$value];

  my $removed = $cell->remove_possibility($value);

  print $deduction->reason . "\n" if $removed && $deduction->reason;

  return $removed ? 1 : 0;
}

sub cell_from_row_column {
  my ( $self, $row, $column ) = @_;
  my $cell;
  $cell = $self->rows->[$row]->[$column];
  return $cell;
}

sub find_and_set_hidden_singles {  # Hidden Single: only one cell in a unit can contain a value
  my $self = shift;

  my @deductions = Sudoku::Strategy::HiddenSingles->new->apply($self);

  return $self->apply_deductions(@deductions);
}

# Logic for this method was incorrect because it was based on my incorrect understanding of what a
# "Remote Pair" is.  I plan on coming back here and fixing this later as there are serveral puzzles
# in sudoku17-50 that will be solved with the proper find of a single remote pair.
sub find_remote_pairs {
  my $self = shift;

  my @deductions = Sudoku::Strategy::RemotePairs->new->apply($self);

  return $self->apply_deductions(@deductions);
}

sub find_naked_pairs {
  my $self = shift;

  my @deductions = Sudoku::Strategy::NakedPairs->new->apply($self);

  return $self->apply_deductions(@deductions);
}

sub find_x_wings {
  my $self = shift;

  my @deductions = Sudoku::Strategy::XWing->new->apply($self);

  return $self->apply_deductions(@deductions);
}

sub find_hidden_pairs {
  my $self = shift;

  my @deductions = Sudoku::Strategy::HiddenPairs->new->apply($self);

  return $self->apply_deductions(@deductions);
}

# Pointing / Claiming: a candidate whose possible locations in one unit are confined to a single intersecting unit
sub find_pointing_claiming {
  my $self = shift;

  my @deductions = Sudoku::Strategy::PointingClaiming->new->apply($self);

  return $self->apply_deductions(@deductions);
}

# This method was meant to be a helper to the find_remote_pairs method which is presently abandonded.
sub pairs_possible {
  my $self = shift;
  my $debug = 0;
  my $pairs = {};
  print "Begin search for pairs.\n" if ($debug);
  foreach my $cell ( @{ $self->cells } ) {
    if ( $cell->possibilities->[0] == 2 ) {
      my $pair = "";
      foreach my $value ( @{ $cell->possibilities }[1..9] ) {
        $pair .= $value if $value;
      }
      printf "Pair %d found in cell ( %d, %d, %d ).\n"
             , $pair
             , ( $cell->row + 1 )
             , ( $cell->column + 1 )
             , ( $cell->box + 1 ) if ($debug);
      push ( @{ $pairs->{ $pair } }, $cell );
    }
  }
  if ($debug) {
    print "Pair search yeilds:\n";
    foreach my $key ( keys %{ $pairs } ) {
      printf "%s: %d\n", $key, scalar ( @{ $pairs->{$key} } );
    }
  }
  return $pairs;
}

# Find all cells with only two possible candidate values
# return them in in a hash pairs
# eg. $pairs->{ "row:7 -> 57" } would be an array containing all cells with only 5 and 7 candidate values in row 7.
# This method is used only in the find_naked_pairs method, but will likely be useful in the find_remote_pairs method
# as well.
sub pairs_possible_by_cluster {
  my $self = shift;
  my $debug = 0;
  my $pairs = {};
  print "Begin search for naked pairs.\n" if ($debug);
  foreach my $cell ( @{ $self->cells } ) {
    if ( $cell->possibilities->[0] == 2 ) {
      my $pair = "";
      foreach my $value ( @{ $cell->possibilities }[1..9] ) {
        $pair .= $value if $value;
      }
      printf "Naked pair %d found in cell ( %d, %d, %d ).\n"
             , $pair
             , ( $cell->row + 1 )
             , ( $cell->column + 1 )
             , ( $cell->box + 1 ) if ($debug);
      push ( @{ $pairs->{ "row:" . $cell->row    . " -> " . $pair } }, $cell );
      push ( @{ $pairs->{ "col:" . $cell->column . " -> " . $pair } }, $cell );
      push ( @{ $pairs->{ "box:" . $cell->box    . " -> " . $pair } }, $cell );
    }
  }
  if ($debug) {
    print "Naked pair search yeilds:\n";
    foreach my $key ( keys %{ $pairs } ) {
      printf "%s: %d\n", $key, scalar ( @{ $pairs->{$key} } );
    }
  }
  return $pairs;
}

sub possibilities_hash {
  my $self = shift;
  my $possibility_counts = {};
  my $possible_value;
  my $cluster = 0;
  my $string = '';
  foreach my $row ( @{ $self->rows } ) {
    foreach my $cell ( @{ $row } ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach my $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          #                               "row0:7"
          push ( @{ $possibility_counts->{"row$cluster:" .$possible_value} } , $cell );
        }
      }
    }
    $cluster++;
  }
  $cluster = 0;
  foreach my $column ( @{ $self->columns } ) {
    foreach my $cell ( @{ $column } ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach my $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          push ( @{ $possibility_counts->{"col$cluster:" .$possible_value} } , $cell );
        }
      }
    }
    $cluster++;
  }
  $cluster = 0;
  foreach my $box ( @{ $self->boxes } ) {
    foreach my $cell ( @{ $box } ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach my $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          push ( @{ $possibility_counts->{"box$cluster:" .$possible_value} } , $cell );
        }
      }
    }
    $cluster++;
  }
  return $possibility_counts;
}

sub remove_my_solution_from_my_mates  {
  my($self,$cell) = @_;
  my($value) = $cell->value;
  foreach ( @{ $self->row_mates_of($cell) } ) {
    $_->remove_possibility($value);
  }
  foreach ( @{ $self->column_mates_of($cell) } ) {
    $_->remove_possibility($value);
  }
  foreach ( @{ $self->box_mates_of($cell) } ) {
    $_->remove_possibility($value);
  }
}

sub row_mates_of {  # return an array ref to an array containing all the other cells on my row that aren't me
  my($self,$cell) = @_;
  my $row = $cell->row;
  my $a = [ grep { $_->column != $cell->column } @{$self->rows->[$row]} ];
# print "row: " . ( $row + 1 ) . "; number of cells: " . scalar @$a . "\n";
  $a;
}

sub column_mates_of {  # return an array ref to an array containing all the other cells on my column that aren't me
  my($self,$cell) = @_;
  my $column = $cell->column;
  my $a = [ grep { $_->row != $cell->row } @{$self->columns->[$column]} ];
# print "column " . ( $column + 1 ) . "; number of cells: " . scalar @$a . "\n";
  $a;
}

sub box_mates_of {  # return an array ref to an array containing all the other cells on my box that aren't me
  my($self,$cell) = @_;
  my $box = $cell->box;
# print "my box has " . scalar @{$self->boxes->[$box]} . " cells in it.\n";
  my $a = [ grep { $_->column != $cell->column or $_->row != $cell->row } @{$self->boxes->[$box]} ];
# print "box " . ( $box + 1 ) . "; number of cells: " . scalar @$a . "\n";
  $a;
}

sub intersections {
  my( $self, $cell_1, $cell_2 ) = @_;
  my $intersections = [];
  if ( $cell_1 == $cell_2 ) {                            # SAME ROW, SAME COLUMN, SAME BOX 1,1,1
    # 1 1 1 ( Same cell is NOT ALLOWED!)
    print "Cell::intersections called with self as the 'other cell'... cut it out!\n";
    exit 1;
  } else {                                               # DIFF SOMETHING                  X,Y,Z  one+ is 0
    if ( $cell_1->row == $cell_2->row ) {                # SAME ROW, DIFF COLUMN
      if ( $cell_1->box == $cell_2->box ) {              # SAME ROW, DIFF COLUMN, SAME BOX 1,0,1
        # members of the shared box and shared row
        push ( @$intersections, grep { $_->column != $cell_2->column }                             @{ $self->row_mates_of($cell_1) } );
        push ( @$intersections, grep { $_->row != $cell_2->row and $_->column != $cell_2->column } @{ $self->box_mates_of($cell_1) } );
      } else {                                           # SAME ROW, DIFF COLUMN, DIFF BOX 1,0,0
        # just members of the shared row
        push ( @$intersections, grep { $_->column != $cell_2->column } @{ $self->row_mates_of($cell_1) } );
      }
    } else {                                             # DIFF ROW
      if ( $cell_1->column == $cell_2->column ) {        # DIFF ROW, SAME COLUMN
        if ( $cell_1->box == $cell_2->box ) {            # DIFF ROW, SAME COLUMN, SAME BOX 0,1,1
          # members of the shared box and shared column
          push ( @$intersections, grep { $_->row != $cell_2->row } @{ $self->column_mates_of($cell_1) } );
          push ( @$intersections, grep { $_->row != $cell_2->row and $_->column != $cell_2->column } @{ $self->box_mates_of($cell_1) } );
        } else {                                         # DIFF ROW, SAME COLUMN, DIFF BOX 0,1,0
          # just members of the shared column
          push ( @$intersections, grep { $_->row != $cell_2->row } @{ $self->column_mates_of($cell_1) } );
        }
      } else {                                           # DIFF ROW, DIFF COLUMN
        if ( $cell_1->box == $cell_2->box ) {            # DIFF ROW, DIFF COLUMN, SAME BOX 0,0,1
          # just members of the shared box
          push ( @$intersections, grep { $_->row != $cell_2->row and $_->column != $cell_2->column } @{ $self->box_mates_of($cell_1) } );
        } else {                                         # DIFF ROW, DIFF COLUMN, DIFF BOX 0,0,0
          # just two intersecting cells
          # (row1, col2) and (row2, col1)
          push ( @$intersections, $self->cell_from_row_column( $cell_1->row, $cell_2->column) );
          push ( @$intersections, $self->cell_from_row_column( $cell_2->row, $cell_1->column) );
        }
      }
    }
  }
  return $intersections;
}

sub unsolved_cells {
  my($self) = shift;
  my $unsolved = [ ];
  push ( @{$unsolved}, grep { not $_->value } @{$self->cells} ) ;
# print "Found " . scalar @{$unsolved} . " unsolved cells.\n";
  return $unsolved;
}

sub solved_cells {
  my($self) = shift;
  my $solved = [ ];
  push ( @{$solved}, grep { $_->value } @{$self->cells} ) ;
# print "Found " . scalar @{$solved} . " solved cells.\n";
  return $solved;
}

# Print status of all the cells
sub status {
  my $self = shift;
  print "Showing status of all cells:\n";
  foreach my $cell ( @{$self->cells} ) {
    printf "( %d, %d, %d ) ", ( 1 + $cell->row ), ( 1 + $cell->column ), ( 1 + $cell->box );
    if ( $cell->value ) {
      if ( $cell->given ) {
        print "Given:    " . $cell->value . "\n";
      } else {
        print "Solved:   " . $cell->value . "\n";
      }
    } else {
      printf "%d left -> " , $cell->possibilities->[0];
      printf "%-27s\n", join( ', ', ( grep { $_ != 0 } @{ $cell->possibilities }[1..9] ) );
    }
  }
}

# Print status of all the cells in a 3 column outputs
sub multi_column_status {
  my $self = shift;
  print "Showing status of all cells:\n";
  my $lines = [];
  my $line = 0;
  foreach my $cell ( @{$self->cells} ) {
    my $entry = '';
    $entry .= sprintf "( %d, %d, %d ) ", ( 1 + $cell->row ), ( 1 + $cell->column ), ( 1 + $cell->box ); # 12 characters
    if ( $cell->value ) {
      if ( $cell->given ) {
        $entry .= sprintf "Given:    %-27s", $cell->value; # 38 characters
      } else {
        $entry .= sprintf "Solved:   %-27s", $cell->value; # 38 characters
      }
    } else {
      $entry .= sprintf "%d left -> " , $cell->possibilities->[0]; # 10 characters
      $entry .= sprintf "%-27s", join( ', ', ( grep { $_ != 0 } @{ $cell->possibilities }[1..9] ) ); # 27 characters
    }
    # each column will be 12+10+27 = 50 characters wide
    $lines->[($line++)%27] .= " $entry";
  }
  print "$_\n" foreach @$lines;
}

# Simplest printout
sub out {
  my($self) = shift;
  for ( my($r) = 0; $r <= 8; $r++ ) {
    my $off = $r * 9;
    print "   ";
    printf "%3d", $self->cells->[ $off + $_ ]->value for ( 0 .. 8 );
    print "\n";
  }
}

# Prettier printout
sub pretty_print {
  my($self) = shift;
  my($format);
  $format .= "     1   2   3   4   5   6   7   8   9  \n";
  $format .= "   +---+---+---+---+---+---+---+---+---+\n";
  $format .= " 1 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 2 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 3 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   +---+---+---+---+---+---+---+---+---+\n";
  $format .= " 4 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 5 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 6 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   +---+---+---+---+---+---+---+---+---+\n";
  $format .= " 7 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 8 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 9 | %s ' %s ' %s | %s ' %s ' %s | %s ' %s ' %s |\n";
    $format .= "   +---+---+---+---+---+---+---+---+---+\n";

  printf $format, ( map { $_->value == 0 ?  ' ' : $_->value } @{$self->cells} ) ;
}

# Best and most complete printout
sub big_print  {
  my($self) = shift;
  my $grid = [];
  #        ( ( $col + 1 ) * 8 )
  #                        1         2         3         4         5         6         7
  #              0123456789012345678901234567890123456789012345678901234567890123456789012345678
  $grid->[ 0] = "                                                                               "; #  0   center of cell is ( $row * 4 )
  $grid->[ 1] = "        1       2       3       4       5       6       7       8       9      "; #  1
  $grid->[ 2] = "    +-------+-------+-------+-------+-------+-------+-------+-------+-------+  "; #  2      __________ row ______________
  $grid->[ 3] = "    |       '       '       |       '       '       |       '       '       |  "; #  3      int ( ( $val - 1 ) / 3 )  - 1
  $grid->[ 4] = "  1 |       '       '       |       '       '       |       '       '       |  "; #  4   1:         0                  -1
  $grid->[ 5] = "    |       '       '       |       '       '       |       '       '       |  "; #  5   2:         0                  -1
  $grid->[ 6] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; #  6   3:         0                  -1
  $grid->[ 7] = "    |       '       '       |       '       '       |       '       '       |  "; #  7   4:         1                   0
  $grid->[ 8] = "  2 |       '       '       |       '       '       |       '       '       |  "; #  8   5:         1                   0
  $grid->[ 9] = "    |       '       '       |       '       '       |       '       '       |  "; #  9   6:         1                   0
  $grid->[10] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; # 10   7:         2                   1
  $grid->[11] = "    |       '       '       |       '       '       |       '       '       |  "; # 11   8:         2                   1
  $grid->[12] = "  3 |       '       '       |       '       '       |       '       '       |  "; # 12   9:         2                   1
  $grid->[13] = "    |       '       '       |       '       '       |       '       '       |  "; # 13
  $grid->[14] = "    +-------+-------+-------+-------+-------+-------+-------+-------+-------+  "; # 14   _____________ col ______________
  $grid->[15] = "    |       '       '       |       '       '       |       '       '       |  "; # 15   ( ( ( $val - 1 ) % 3 ) - 1 ) * 2
  $grid->[16] = "  4 |       '       '       |       '       '       |       '       '       |  "; # 16   1:     0                -1    -2
  $grid->[17] = "    |       '       '       |       '       '       |       '       '       |  "; # 17   2:     1                 0     0
  $grid->[18] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; # 18   3:     2                 1     2
  $grid->[19] = "    |       '       '       |       '       '       |       '       '       |  "; # 19   4:     0                -1    -2
  $grid->[20] = "  5 |       '       '       |       '       '       |       '       '       |  "; # 20   5:     1                 0     0
  $grid->[21] = "    |       '       '       |       '       '       |       '       '       |  "; # 21   6:     2                 1     2
  $grid->[22] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; # 22   7:     0                -1    -2
  $grid->[23] = "    |       '       '       |       '       '       |       '       '       |  "; # 23   8:     1                 0     0
  $grid->[24] = "  6 |       '       '       |       '       '       |       '       '       |  "; # 24   9:     2                 1     2
  $grid->[25] = "    |       '       '       |       '       '       |       '       '       |  "; # 25
  $grid->[26] = "    +-------+-------+-------+-------+-------+-------+-------+-------+-------+  "; # 26
  $grid->[27] = "    |       '       '       |       '       '       |       '       '       |  "; # 27
  $grid->[28] = "  7 |       '       '       |       '       '       |       '       '       |  "; # 28
  $grid->[29] = "    |       '       '       |       '       '       |       '       '       |  "; # 29
  $grid->[30] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; # 30
  $grid->[31] = "    |       '       '       |       '       '       |       '       '       |  "; # 31
  $grid->[32] = "  8 |       '       '       |       '       '       |       '       '       |  "; # 32
  $grid->[33] = "    |       '       '       |       '       '       |       '       '       |  "; # 33
  $grid->[34] = "    + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- + ----- +  "; # 34
  $grid->[35] = "    |       '       '       |       '       '       |       '       '       |  "; # 35
  $grid->[36] = "  9 |       '       '       |       '       '       |       '       '       |  "; # 36
  $grid->[37] = "    |       '       '       |       '       '       |       '       '       |  "; # 37
  $grid->[38] = "    +-------+-------+-------+-------+-------+-------+-------+-------+-------+  "; # 38

   foreach my $cell ( @{ $self->solved_cells } ) {
    substr( $grid->[ ( $cell->row + 1 ) * 4 ],
            ( ( $cell->column + 1 ) * 8 ),
            1, $cell->value);
  }

  foreach my $cell ( @{ $self->unsolved_cells } ) {
    foreach my $value ( grep { $_ } ( @{$cell->possibilities}[1..9] ) ) {
      substr( $grid->[ ( ( $cell->row + 1 ) * 4 )   +   int ( ( $value - 1 ) / 3 ) - 1 ],
              ( ( $cell->column + 1 ) * 8 ) + ( ( ( $value - 1 ) % 3 ) - 1 ) * 2,
              1, $value);
      }
  }

  print "$_\n" foreach ( @{ $grid } );
}

1;
__END__

  $format .= "     1   2   3   4   5   6   7   8   9  \n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  $format .= " 1 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 2 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 3 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  $format .= " 4 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 5 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 6 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  $format .= " 7 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 8 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 9 I %s | %s | %s I %s | %s | %s I %s | %s | %s I\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";

       1   2   3   4   5   6   7   8   9
     +===+===+===+===+===+===+===+===+===+
   1 I   |   |   I   |   |   I   |   |   I
     + - + - + - + - + - + - + - + - + - +
   2 I   | 1 |   I   | 2 |   I   | 3 |   I
     + - + - + - + - + - + - + - + - + - +
   3 I   |   |   I   |   |   I   |   |   I
     +===+===+===+===+===+===+===+===+===+
   4 I   |   |   I   |   |   I   |   |   I
     + - + - + - + - + - + - + - + - + - +
   5 I   | 4 |   I   | 5 |   I   | 6 |   I
     + - + - + - + - + - + - + - + - + - +
   6 I   |   |   I   |   |   I   |   |   I
     +===+===+===+===+===+===+===+===+===+
   7 I   |   |   I   |   |   I   |   |   I
     + - + - + - + - + - + - + - + - + - +
   8 I   | 7 |   I   | 8 |   I   | 9 |   I
     + - + - + - + - + - + - + - + - + - +
   9 I   |   |   I   |   |   I   |   |   I
     +===+===+===+===+===+===+===+===+===+



  Difficulty         number range of given numbers, other attributes as of yet unknown or unidentified
        0 - easy
        1 - medium
        2 - hard
        3 - crazy
        4 - diabolical

   Puzzle
     Notes           -> string describing origin of the puzzle
     Difficulty      -> 0 - easy, 1 - medium, 2 - hard, 3 - crazy, 4 - diabolical
     Rows            -> array 1 .. 9, pointers to each member row
     Columns         -> array 1 .. 9, pointers to each member columns
     Boxs            -> array 1 .. 9, pointers to each member box

   Row
     Members         -> array 1 .. 9, with pointers to cells in this Row

   Column
     Members         -> array 1 .. 9, with pointers to cells in this Column

   Box
     Members         -> array 1 .. 9, with pointers to cells in this Box

   Cell
     Given           -> boolean, true if given value was 'given' in original puzzle
     Value           -> single digit 1 - 9
     Possible values -> array 1 .. 9, with numbers for those that are possible and zeros for those that are not.
                        example, [ 1, 0, 0, 4, 0, 0, 0, 0, 0, 9 ] would be a cell who's possible remaining values would be 1, 4 and 9
     Box             -> number from 1 - 9, to which box    does this cell belong
     Row             -> number from 1 - 9, to which row    does this cell belong
     Column          -> number from 1 - 9, to which column does this cell belong


     substr EXPR,OFFSET,LENGTH,REPLACEMENT
     substr EXPR,OFFSET,LENGTH
     substr EXPR,OFFSET

First character is at offset 0

OFFSET is negative   == that far from the end of the string.
no LENGTH            == everything to the end of the string.
LENGTH is negative   == leaves that many characters off the end of the string.

To keep the string the same length you may need to pad
or chop your value using "sprintf".


OFFSET and LENGTH partly outside, only part returned.
OFFSET and LENGTH completely outside, UNDEF returned.

Here's an example showing the behavior for boundary cases:

  my $name = 'fred';
  substr($name, 4) = 'dy';       # $name is now 'freddy'
  my $null = substr $name, 6, 2; # returns '' (no warning)
  my $oops = substr $name, 7;    # returns undef, with warning
  substr($name, 7) = 'gap';      # fatal error

  my $str="abd123hij";		     # 2 ways to replace 123 with efg
  substr($str, 2, 3, 'efg');	 # assign 4th arg.
  substr($str, 2, 3)='efg';	     # substr as an lvalue

