package Sudoku::Strategy::NakedPairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Naked Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my $progress = 0;
  print "Looking for Naked Pairs, any two cells with the same\n";
  print "pair of possible values that exist in the same cluster [row column or box]):\n";

  my $pairs = $grid->pairs_possible_by_cluster;

  # look for pairs that have 2 cells

  foreach my $key ( grep { scalar ( @{ $pairs->{$_} } == 2 ) } keys %{ $pairs } ) {
    # we have a naked pair
    if ( $key =~ /row/ ) {
      my ( $col1, $col2, $row, $pair1, $pair2 );
      ( $row, $pair1, $pair2 )  = ( $key =~ /row:(\d) -> (\d)(\d)/ );
      # find the columns of the 2 cells holding the naked pair
      $col1 = $pairs->{ $key }[0]->column;
      $col2 = $pairs->{ $key }[1]->column;
      foreach my $cell ( grep { not $_->value } ( @{ $grid->rows->[$row] } ) ) { # find unsolved cells in this row that aren't either of the naked pair.
        my $col = $cell->column;
        next if ( $col == $col1 or  $col == $col2 );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            printf "Naked pair in row %d, cols %d and %d leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $row + 1 , $col1 + 1 , $col2 + 1 , $pair1
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            printf "Naked pair in row %d, cols %d and %d leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $row + 1 , $col1 + 1 , $col2 + 1 , $pair2
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
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
      foreach my $cell ( grep { not $_->value } ( @{ $grid->columns->[$col] } ) ) { # find unsolved cells in this column that aren't either of the naked pair.
        my $row = $cell->row;
        next if ( $row == $row1 or  $row == $row2 );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            printf "Naked pair in col %d, rows %d and %d leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $col + 1 , $row1 + 1 , $row2 + 1 , $pair1
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            printf "Naked pair in col %d, rows %d and %d leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $col + 1 , $row1 + 1 , $row2 + 1 , $pair2
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
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
      foreach my $cell ( grep { not $_->value } ( @{ $grid->boxes->[$box] } ) ) { # find unsolved cells in this row that aren't either of the naked pair.
        my $row = $cell->row;
        my $col = $cell->column;
        next if ( ( $row == $row1 and $col == $col1 )
               or ( $row == $row2 and $col == $col2 ) );
        # if $pair1 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair1] ) {
          if ( $cell->possibilities->[$pair1] ) {
            printf "Naked pair in box %d, cells ( %d, %d ) and ( %d, %d ) leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $box + 1 , $row1 + 1 , $col1 + 1 , $row2 + 1 , $col2 + 1
                   , $pair1
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
            $cell->possibilities->[$pair1] = 0;
            $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
            $progress++;
          }
        }
        # if $pair2 is still possible in this cell, remove it.
        if ( $cell->possibilities->[$pair2] ) {
          if ( $cell->possibilities->[$pair2] ) {
            printf "Naked pair in box %d, cells ( %d, %d ) and ( %d, %d ) leads to %d being removed from cell ( %d, %d, %d ).\n"
                   , $box + 1 , $row1 + 1 , $col1 + 1 , $row2 + 1 , $col2 + 1
                   , $pair2
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
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

1;
