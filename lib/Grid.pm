package Grid;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Carp;
use Cell;

has 'difficulty'  => (isa => 'Difficulty', is => 'rw');
has 'notes'       => (isa => 'String',     is => 'rw');
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
# print $self->cells   . " <- cells\n";
# print $self->rows    . " <- rows\n";
# print $self->columns . " <- columns\n";
# print $col . " <- col\n";
# print $self->columns->[0] . " <- column->[0]\n";
# print $self->boxes   . " <- boxes\n";
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
    push ( $self->rows->[$row],    $new_cell );
    push ( $self->columns->[$col], $new_cell );
    push ( $self->boxes->[$box],   $new_cell );
  }
# print "We have populated the grid with the given clues,
# now we will remove the given's as possibilities from their rows, columns and boxes.\n";
  foreach ( grep { $_->value } @{$self->cells} ) {
    $self->solved( 1 + $self->solved );
    $self->remove_my_solution_from_my_mates($_);
  }
}

sub find_and_set_singletons {  # a singleton is a cell which has only one possible value left
  my $self  = shift;
  my $progress = 0;
  print "Looking for Singletons (cells with only one possible value left):\n";
  foreach my $this_cell ( @{ $self->cells } ) {
    # check if this cell has only one possibility left, and if so set it and clear it's value from row, column and box neighboors.
    if ( $this_cell->possibilities->[0] == 1 ) {
      $progress++;
      $self->solved(1+$self->solved);
      my($value,) = grep { $_ != 0 } @{$this_cell->possibilities}[1..9];
      $this_cell->value($value);
      printf "Setting cell ( %d, %d, %d ) to %d\n"
        , ( $this_cell->row + 1 )
        , ( $this_cell->column + 1 )
        , ( $this_cell->box + 1 )
        , $this_cell->value;
      $this_cell->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
      $self->remove_my_solution_from_my_mates($this_cell);
    }
  }
  print "Found and set $progress cells this singletons search pass.\n\n";
  return $progress;
}

sub find_and_set_lone_representatives {  # a lone_representative is only cell with a possible value in a cell cluster (row column or box)
  my $self  = shift;
  my $progress  = 0;
  # Plan: foreach cluster, count the number of cells foreach unsolved value
  # case 1) value has only one cell, this is a "lone representative" and may be assigned immediately
  # case 2) value has two or three cells.  If these cells all reside in another cluster, this value may be removed as a possibility 
  #         in that other cluster's other member cells
  # case 3) naked pair    two   cells with the same two   possibilites put this one in it's own method
  # case 4) naked triplet three cells with the same three possibilites put this one in it's own method as well
  # Starting with case 2:
  
  print "Looking for Lone representatives (possible value's present in only one cell of a cluster [row column or box]):\n";
  my ( $possibility_counts, $possible_value);
  # CHECK BOXES FOR LONE REPRESENTATIVES
  foreach my $box ( @{$self->boxes} ) {
    foreach my $cell ( @{$box} ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach $possible_value ( @{ $cell->possibilities } ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          push ( @{ $possibility_counts->{$possible_value} } , $cell );
        }
      }
    }
    # we now have a cell count of all possible values left in this box
    # we search these counts for a 1, this represents a value that has only one cell in this box
    # in which this value is still a possibility.
    foreach $possible_value ( keys %{ $possibility_counts } ) {
      if ( scalar ( @{ $possibility_counts->{$possible_value} } ) == 1 ) { # found a lone representative cell/value
        my $lone_representative = $possibility_counts->{$possible_value}[0];
        $lone_representative->value($possible_value);
        $self->remove_my_solution_from_my_mates($lone_representative);
        $progress++;
      }
    }
  }

  # CHECK ROWS FOR LONE REPRESENTATIVES
  foreach my $row ( @{$self->rows} ) {
    foreach my $cell ( @{$row} ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach $possible_value ( @{ $cell->possibilities } ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          push ( @{ $possibility_counts->{$possible_value} } , $cell );
        }
      }
    }
    # we now have a cell count of all possible values left in this row
    # we search these counts for a 1, this represents a value that has only one cell in this row
    # in which this value is still a possibility.
    foreach $possible_value ( keys %{ $possibility_counts } ) {
      if ( scalar ( @{ $possibility_counts->{$possible_value} } ) == 1 ) { # found a lone representative cell/value
        my $lone_representative = $possibility_counts->{$possible_value}[0];
        $lone_representative->value($possible_value);
        $self->remove_my_solution_from_my_mates($lone_representative);
        $progress++;
      }
    }
  }

  # CHECK COLUMNS FOR LONE REPRESENTATIVES
  foreach my $column ( @{$self->columns} ) {
    foreach my $cell ( @{$column} ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach $possible_value ( @{ $cell->possibilities } ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
          push ( @{ $possibility_counts->{$possible_value} } , $cell );
        }
      }
    }
    # we now have a cell count of all possible values left in this column
    # we search these counts for a 1, this represents a value that has only one cell in this column
    # in which this value is still a possibility.
    foreach $possible_value ( keys %{ $possibility_counts } ) {
      if ( scalar ( @{ $possibility_counts->{$possible_value} } ) == 1 ) { # found a lone representative cell/value
        my $lone_representative = $possibility_counts->{$possible_value}[0];
        $lone_representative->value($possible_value);
        $self->remove_my_solution_from_my_mates($lone_representative);
        $progress++;
      }
    }
  }
  print "Found and set $progress cells this lone representatives search pass.\n\n";
  return $progress;
}

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

sub remove_my_solution_from_my_mates  {
  my($self,$cell) = @_;
  my($value) = $cell->value;
  foreach ( @{ $self->row_mates_of($cell) } ) {
#   print 'r ';
    $_->remove_possility($value);
  }
  foreach ( @{ $self->column_mates_of($cell) } ) {
#   print 'c ';
    $_->remove_possility($value);
  }
  foreach ( @{ $self->box_mates_of($cell) } ) {
#   print 'b ';
    $_->remove_possility($value);
  }
# print "\n";
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

sub unsolved_cells {
  my($self) = shift;
  my $unsolved = [ ];
  push ( @{$unsolved}, grep { not $_->value } @{$self->cells} ) ;
  return $unsolved;
}

sub solved_cells {
  my($self) = shift;
  my $solved = [ ];
  push ( @{$solved}, grep { $_->value } @{$self->cells} ) ;
  return $solved;
}

sub out {
  my($self) = shift;
  for ( my($r) = 0; $r <= 8; $r++ ) {
    my $off = $r * 9;
    print "   ";
    printf "%3d", $self->cells->[ $off + $_ ]->value for ( 0 .. 8 ); 
    print "\n";
  }
}

sub pretty_print {
  my($self) = shift;
  my($format);
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
  printf $format, ( map { $_->value == 0 ? ' ' : $_->value } @{$self->cells} ) ;
}

1;
__END__

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
