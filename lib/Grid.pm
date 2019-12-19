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
  print "Looking for Singletons (cells with only one possible value left) :\n";
  foreach my $this_cell ( @{ $self->cells } ) {
    # check if this cell has only one possibility left, and if so set it and clear it's value from row, column and box neighboors.
    if ( $this_cell->possibilities->[0] == 1 ) {
      $progress++;
      $self->solved( 1 + $self->solved );
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
  my $possible_value;
  my $possibility_counts = {};
  # Plan: foreach cluster, count the number of cells foreach unsolved value
  # case 1) value has only one cell, this is a "lone representative" and may be assigned immediately
  # case 2) value has two or three cells.  If these cells all reside in another cluster, this value may be removed as a possibility 
  #         in that other cluster's other member cells
  # case 3) naked pair    two   cells with the same two   possibilites put this one in it's own method
  # case 4) naked triplet three cells with the same three possibilites put this one in it's own method as well
  # Starting with case 2:

  print "Looking for Lone representatives (possible value's present in only one cell of a cluster [row column or box]):\n";
  $possibility_counts = $self->possibilities_hash;
  # we now have a cell count of all possible values for all cells organized by cell cluster
  # we will search these counts for a 1, this represents a value that has only one cell in this box
  # in which this value is still a possibility.
  # CHECK BOXES FOR LONE REPRESENTATIVES
  foreach my $key ( sort grep { $_ =~ /box/ } keys %{ $possibility_counts } ) {
#   print "DEBUG - key for possibility_counts is $key\n"; next;
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 1 ) { # found a lone representative cell/value
      ( $possible_value = $key ) =~ s/box\d://;
      $progress++;
      $self->solved( 1 + $self->solved );
      my $lone_representative = $possibility_counts->{$key}[0];
      $lone_representative->value($possible_value);
      $lone_representative->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
      $self->remove_my_solution_from_my_mates($lone_representative);
      printf "Lone in Box    Setting cell ( %d, %d, %d ) to %d\n"
        , ( $lone_representative->row + 1 )
        , ( $lone_representative->column + 1 )
        , ( $lone_representative->box + 1 )
        , $possible_value;
    }
  }

  $possibility_counts = $self->possibilities_hash;
  # we now have a new cell count of all possible values for all cells organized by cell cluster
  # we will search these counts for a 1, this represents a value that has only one cell in this row
  # in which this value is still a possibility.
  # CHECK ROWS FOR LONE REPRESENTATIVES
  foreach my $key ( grep { $_ =~ /row/ } keys %{ $possibility_counts } ) {
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 1 ) { # found a lone representative cell/value
      ( $possible_value = $key ) =~ s/row\d://;
      $progress++;
      $self->solved( 1 + $self->solved );
      my $lone_representative = $possibility_counts->{$key}[0];
      $lone_representative->value($possible_value);
      $lone_representative->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
      $self->remove_my_solution_from_my_mates($lone_representative);
      printf "Lone in Row    Setting cell ( %d, %d, %d ) to %d\n"
        , ( $lone_representative->row + 1 )
        , ( $lone_representative->column + 1 )
        , ( $lone_representative->box + 1 )
        , $possible_value;
    }
  }

  $possibility_counts = $self->possibilities_hash;
  # CHECK COLUMNS FOR LONE REPRESENTATIVES
  # we now have a new cell count of all possible values for all cells organized by cell cluster
  # we will search these counts for a 1, this represents a value that has only one cell in this column
  # in which this value is still a possibility.
  foreach my $key ( grep { $_ =~ /col/ } keys %{ $possibility_counts } ) {
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 1 ) { # found a lone representative cell/value
      ( $possible_value = $key ) =~ s/col\d://;
      $progress++;
      $self->solved( 1 + $self->solved );
      my $lone_representative = $possibility_counts->{$key}[0];
      $lone_representative->value($possible_value);
      $lone_representative->possibilities( [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
      $self->remove_my_solution_from_my_mates($lone_representative);
      printf "Lone in Column Setting cell ( %d, %d, %d ) to %d\n"
        , ( $lone_representative->row + 1 )
        , ( $lone_representative->column + 1 )
        , ( $lone_representative->box + 1 )
        , $possible_value;
      $progress++;
    }
  }

  print "Found and set $progress cells this lone representatives search pass.\n\n";
  return $progress;
}

sub find_naked_pairs {
  my $self = shift;
  my $progress = 0;
  print "Looking for Naked Pairs, any two cells with the same\n";
  print "pair of possible values that exist in the same cluster [row column or box]):\n";

  my $pairs = $self->pairs_possible;

  # look for pairs that have 2 cells

  foreach my $key ( grep { scalar ( @{ $pairs->{$_} } == 2 ) } keys %{ $pairs } ) {
    # we have a naked pair
    if ( $key =~ /row/ ) {
      my ( $col1, $col2, $row, $pair1, $pair2 );
      ( $row, $pair1, $pair2 )  = ( $key =~ /row:(\d) -> (\d)(\d)/ );
      # find the columns of the 2 cells holding the naked pair
      $col1 = $pairs->{ $key }[0]->column;
      $col2 = $pairs->{ $key }[1]->column;
      foreach my $cell ( grep { not $_->value } ( @{ $self->rows->[$row] } ) ) { # find unsolved cells in this row that aren't either of the naked pair.
        my $col = $cell->column;
        next if ( $col == $col1 or  $col == $col2 );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            $cell->possibilities->[$pair2] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
      }
    }

    if ( $key =~ /col/ ) {
      my ( $row1, $row2, $col, $pair1, $pair2 );
      ( $col, $pair1, $pair2 )  = ( $key =~ /col:(\d) -> (\d)(\d)/ );
      # find the columns of the 2 cells holding the naked pair
      $row1 = $pairs->{ $key }[0]->row;
      $row2 = $pairs->{ $key }[1]->row;
      foreach my $cell ( grep { not $_->value } ( @{ $self->columns->[$col] } ) ) { # find unsolved cells in this column that aren't either of the naked pair.
        my $row = $cell->row;
        next if ( $row == $row1 or  $row == $row2 );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            $cell->possibilities->[$pair2] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
      }
    }

    if ( $key =~ /box/ ) {
      my ( $row1, $row2, $col1, $col2, $box, $pair1, $pair2 );
      ( $box, $pair1, $pair2 )  = ( $key =~ /box:(\d) -> (\d)(\d)/ );
      # find the rows and columns of the 2 cells holding the naked pair
      $row1 = $pairs->{ $key }[0]->row;
      $row2 = $pairs->{ $key }[1]->row;
      $col1 = $pairs->{ $key }[0]->column;
      $col2 = $pairs->{ $key }[1]->column;
      foreach my $cell ( grep { not $_->value } ( @{ $self->boxes->[$box] } ) ) { # find unsolved cells in this row that aren't either of the naked pair.
        my $row = $cell->row;
        my $col = $cell->column;
        next if ( ( $row == $row1 and $col == $col1 )
               or ( $row == $row2 and $col == $col2 ) );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            $cell->possibilities->[$pair2] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
      }
    }
  }

  print "Found and processed $progress naked pairs.\n\n";
  return $progress;
}

# An imaginary value is a value whose only possible locations in one cluster are all exclusively in a single cluster of a different kind 
# See see the notes_imaginary_values.txt
sub find_imaginary_values {
  my $self  = shift;
  my $progress = 0;
  my $possibility_counts;
  my $possible_value;
  print "Looking for Imaginary Values (all 2 or 3 representatives of a given value in a cluster share all belong to another cluster):\n";

  $possibility_counts = $self->possibilities_hash;
  foreach my $key ( sort grep { $_ =~ /box/ } keys %{ $possibility_counts } ) {
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 2 or scalar ( @{ $possibility_counts->{$key} } ) == 3 ) {
      # examine all cells in the possibility count and see if they are all in the row or same column
      my ( $cell_rows, $cell_cols, $box );
      foreach my $cell ( @{ $possibility_counts->{$key} } ) {
#       printf "IV-box: examining cell at ( %d, %d, %d ).\n"
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
        $cell_rows->{$cell->row}++;
        $cell_cols->{$cell->column}++;
      }
      # we now have a count of the unique cols and rows of these cells.
      # if either is a count of one, then all cells share the same row or column
      if ( ( scalar keys %{$cell_rows} ) == 1 ) {
        # all cells in this box representing this possible value live in the same row
        # if there are any cells in this row but outside of this box we can safely
        # remove this possible value from these "outside" cells
        my $row = ( keys %{$cell_rows} )[0];
        ( $box, $possible_value ) = ( $key =~ /box(\d):(\d)/);
        # do we have cells with this value outside this box 
        if ( $possibility_counts->{"row" . $row . ":" . $possible_value } and 
             ( scalar @{ $possibility_counts->{"row" . $row . ":" . $possible_value } }
             > scalar @{ $possibility_counts->{$key} } ) ) {
          foreach my $cell ( grep { $_->box != $box } @{ $possibility_counts->{"row" . $row . ":" . $possible_value} } ) {
            $cell->possibilities->[$possible_value] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
#           printf "Imaginary value of %d found in Box %d...   removing it from the cell ( %d, %d, %d ).\n"
#             , $possible_value
#             , $box + 1
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
            $progress++;
          }
        }
      }
      if ( ( scalar keys %{$cell_cols} ) == 1 ) {
        # all cells in this box representing this possible value live in the same column
        # if there are any cells in this column but outside of this box we can safely
        # remove this possible value from these "outside" cells
        my $col = ( keys %{$cell_cols} )[0];
        ( $box, $possible_value ) = ( $key =~ /box(\d):(\d)/);
        # do we have cells with this value outside this box 
        if (   $possibility_counts->{"col" . $col . ":" . $possible_value } and 
             ( scalar @{ $possibility_counts->{"col" . $col . ":" . $possible_value } }
             > scalar @{ $possibility_counts->{$key} } ) ) {
          foreach my $cell ( grep { $_->box != $box } @{ $possibility_counts->{"col" . $col . ":" . $possible_value} } ) {
            $cell->possibilities->[$possible_value] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
#           printf "Imaginary value of %d found in Box %d...   removing it from the cell ( %d, %d, %d ).\n"
#             , $possible_value
#             , $box
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
            $progress++;
          }
        }
      }
    }
  }

  $possibility_counts = $self->possibilities_hash;
  foreach my $key ( sort grep { $_ =~ /row/ } keys %{ $possibility_counts } ) {
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 2 or scalar ( @{ $possibility_counts->{$key} } ) == 3 ) {
      # examine all cells in the possibility count and see if they are all in the row or same column
      my ( $cell_boxes, $row );
      foreach my $cell ( @{ $possibility_counts->{$key} } ) {
#       printf "IV-row: examining cell at ( %d, %d, %d ).\n"
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
        $cell_boxes->{$cell->box}++;
      }
      # we now have a count of the unique boxes
      # if either is a count of one, then all cells share the same row or column
      if ( ( scalar keys %{$cell_boxes} ) == 1 ) {
        # all cells in this box representing this possible value live in the same row
        # if there are any cells in this row but outside of this box we can safely
        # remove this possible value from these "outside" cells
        my $box = ( keys %{$cell_boxes} )[0];
        ( $row, $possible_value ) = ( $key =~ /row(\d):(\d)/);
        # do we have cells with this value outside this box 
        if (   $possibility_counts->{"box" . $box . ":" . $possible_value } and 
             ( scalar @{ $possibility_counts->{"box" . $box . ":" . $possible_value } }
             > scalar @{ $possibility_counts->{$key} } ) ) {
          foreach my $cell ( grep { $_->row != $row } @{ $possibility_counts->{"box" . $box . ":" . $possible_value} } ) {
            $cell->possibilities->[$possible_value] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
#           printf "Imaginary value of %d found in Row %d...   removing it from the cell ( %d, %d, %d ).\n"
#             , $possible_value
#             , $row + 1
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
            $progress++;
          }
        }
      }
    }
  }

  $possibility_counts = $self->possibilities_hash;
  foreach my $key ( sort grep { $_ =~ /col/ } keys %{ $possibility_counts } ) {
    if ( scalar ( @{ $possibility_counts->{$key} } ) == 2 or scalar ( @{ $possibility_counts->{$key} } ) == 3 ) {
      # examine all cells in the possibility count and see if they are all in the row or same column
      my ( $cell_boxes, $col );
      foreach my $cell ( @{ $possibility_counts->{$key} } ) {
#       printf "IV-col $key: examining cell at ( %d, %d, %d ).\n"
#             , ( $cell->row + 1 )
#             , ( $cell->column + 1 )
#             , ( $cell->box + 1 );
        $cell_boxes->{$cell->box}++;
      }
      # we now have a count of the unique boxes
      # if either is a count of one, then all cells share the same row or column
      if ( ( scalar keys %{$cell_boxes} ) == 1 ) {
        # all cells in this box representing this possible value live in the same row
        # if there are any cells in this row but outside of this box we can safely
        # remove this possible value from these "outside" cells
        my $box = ( keys %{$cell_boxes} )[0];
        ( $col, $possible_value ) = ( $key =~ /col(\d):(\d)/);
#       printf "IV-col $key: all cells were in Box %d, this col has %d cells with %d whereas this box %s, %d\n"
#              , $box + 1
#              , $possibility_counts->{$key} ? scalar @{ $possibility_counts->{$key} } : 0
#              , $possible_value
#              , "box" . $box . ":" . $possible_value
#              , $possibility_counts->{"box" . $box . ":" . $possible_value } ? scalar @{ $possibility_counts->{"box" . $box . ":" . $possible_value } } : 0;
        # do we have cells with this value outside this box 
        if (   $possibility_counts->{"box" . $box . ":" . $possible_value } and 
             ( scalar @{ $possibility_counts->{"box" . $box . ":" . $possible_value } }
             > scalar @{ $possibility_counts->{$key} } ) ) {
          foreach my $cell ( grep { $_->column != $col } @{ $possibility_counts->{"box" . $box . ":" . $possible_value} } ) {
            $cell->possibilities->[$possible_value] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            printf "Imaginary value of %d found in Col %d...   removing it from the cell ( %d, %d, %d ).\n"
              , $possible_value
              , $col + 1
              , ( $cell->row + 1 )
              , ( $cell->column + 1 )
              , ( $cell->box + 1 );
            $progress++;
          }
        }
      }
    }
  }

  print "Found and removed $progress possible values from cells via imaginary numbers.\n\n";
  return $progress;
}

sub pairs_possible {
  my $self = shift;
  my $pairs = {};
  print "Begin search for naked pairs.\n";
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
             , ( $cell->box + 1 );
      push ( @{ $pairs->{ "row:" . $cell->row    . " -> " . $pair } }, $cell );
      push ( @{ $pairs->{ "col:" . $cell->column . " -> " . $pair } }, $cell );
      push ( @{ $pairs->{ "box:" . $cell->box    . " -> " . $pair } }, $cell );
    }
  }
  print "Naked pair search yeilds:\n";
# print dump($pairs);
  foreach my $key ( keys %{ $pairs } ) {
    printf "%s: %d\n", $key, scalar ( @{ $pairs->{$key} } );
  }
  return $pairs;
}

sub possibilities_hash {
  my $self = shift;
  my $possibility_counts = {};
  my $possible_value;
  my $cluster = 0;
  foreach my $row ( @{ $self->rows } ) {
    foreach my $cell ( @{ $row } ) {
      if ( not $cell->value ) { # look for unsolved cells in this cluster
        foreach $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
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
        foreach $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
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
        foreach $possible_value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {  # a pointer to the cell is pushed onto the array all of the cell's possible values
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
    $_->remove_possility($value);
  }
  foreach ( @{ $self->column_mates_of($cell) } ) {
    $_->remove_possility($value);
  }
  foreach ( @{ $self->box_mates_of($cell) } ) {
    $_->remove_possility($value);
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

