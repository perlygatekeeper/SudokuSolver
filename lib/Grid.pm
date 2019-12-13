package Grid;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Carp;
use Cell;

has 'difficulty'  => (isa => 'Difficulty', is => 'rw');
has 'notes'       => (isa => 'String',     is => 'rw');
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
# print "We have populated the grid with the given clues, now we will removed the givens from their rows, columns and boxes.\n";
  foreach ( grep { $_->value } @{$self->cells} ) {
#   print "found a cell with a value: "
#     . $_->value . " at (r,c,b): "
#     . ( $_->row + 1 ) . ", "
#     . ( $_->column + 1 ) . ", "
#     . ( $_->box + 1 ) . "\n";
    $self->remove_my_solution_from_my_mates($_);
  }
}

sub find_and_set_singletons {  # a singleton is a cell which has only one possible value left
  my($self) = @_;
  my $progress = 0;
  print "\nLooking for cells with only one possible value left:\n\n";
  foreach $this_cell ( @{ $puzzle->cells } ) {
    # check if this cell has only one possibility left, and if so set it and clear it's row, column and box neighboors.
    if ( $this_cell->possibilities->[0] == 1 ) {
      $progress++;
      my($value,) = grep { $_ != 0 } @{$this_cell->possibilities}[1..9];
      $this_cell->value($value);
      print "Setting cell @ "
        . ( $this_cell->row + 1 ) . ", "
        . ( $this_cell->column + 1 ) . ", "
        . ( $this_cell->box + 1 ) . " to "
        . $this_cell->value
        . "\n";
      $this_cell->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
      $puzzle->remove_my_solution_from_my_mates($this_cell);
    }
  }
  return $progress;
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
