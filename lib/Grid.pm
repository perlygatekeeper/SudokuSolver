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
  my($col) = ( ( $cell - 1 )  % 9 );
  my($row) = int( ( $cell - 1 ) / 9 );
  my($box) = int( ( ( $cell - 1 ) % 9 ) / 3 ) + 3 * int ( int( ( $cell - 1 ) / 9 ) / 3 );
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
    my ($new_cell) =  Cell->new;
    $new_cell->clue($_);
    $new_cell->row($row);
    $new_cell->column($col);
    $new_cell->box($box);

    $self->cells->[$cell++]      = $new_cell;
    push ( $self->rows->[$row],    $new_cell );
    push ( $self->columns->[$col], $new_cell );
    push ( $self->boxes->[$box],   $new_cell );
  }
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
  $format .= " 1 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 2 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 3 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  $format .= " 4 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 5 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 6 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  $format .= " 7 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 8 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   + - + - + - + - + - + - + - + - + - +\n";
  $format .= " 9 H %s | %s | %s H %s | %s | %s H %s | %s | %s H\n";
  $format .= "   +===+===+===+===+===+===+===+===+===+\n";
  printf $format, ( map { $_->value == 0 ? ' ' : $_->value } @{$self->cells} ) ;
}

1;
__END__

       1   2   3   4   5   6   7   8   9  
     +===+===+===+===+===+===+===+===+===+
   1 H   |   |   H   |   |   H   |   |   H
     + - + - + - + - + - + - + - + - + - +
   2 H   | 1 |   H   | 2 |   H   | 3 |   H
     + - + - + - + - + - + - + - + - + - +
   3 H   |   |   H   |   |   H   |   |   H
     +===+===+===+===+===+===+===+===+===+
   4 H   |   |   H   |   |   H   |   |   H
     + - + - + - + - + - + - + - + - + - +
   5 H   | 4 |   H   | 5 |   H   | 6 |   H
     + - + - + - + - + - + - + - + - + - +
   6 H   |   |   H   |   |   H   |   |   H
     +===+===+===+===+===+===+===+===+===+
   7 H   |   |   H   |   |   H   |   |   H
     + - + - + - + - + - + - + - + - + - +
   8 H   | 7 |   H   | 8 |   H   | 9 |   H
     + - + - + - + - + - + - + - + - + - +
   9 H   |   |   H   |   |   H   |   |   H
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
