package Sudoku::Strategy::RemotePairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Remote Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my $progress = 0;
  print "Looking for Remote Pairs, any two cells with the same\n";
  print "pair of possible values that exist in the different clusters [row column or box]):\n";
  my $pairs = $grid->pairs_possible;
  foreach my $key ( grep { scalar( @{ $pairs->{$_} } ) >= 2  } ( keys %{ $pairs } ) ) {
    printf "Remote pair candidate: %s is in %d cells.\n", $key, scalar ( @{ $pairs->{$key} } ) ;
    # we have a pair that appears at least twice
    # compare every two cells that have this pair and see if they
    # share any cluster, if they do, skip them, because then they are a naked pair.
    foreach my $first ( 0 .. ( $#{$pairs->{$key}} - 1 ) ) {         # from first to next-to-last
      foreach my $second ( ( $first + 1 ) .. $#{$pairs->{$key}} ) { # from one after first to last
#       printf "Remote pair: comparing cells numbered  %d and %d.\n", $first, $second;
#       printf "Remote pair: rows    for the cells are %d and %d.\n", $pairs->{$key}[$first]->row,    $pairs->{$key}[$second]->row;
#       printf "Remote pair: columns for the cells are %d and %d.\n", $pairs->{$key}[$first]->column, $pairs->{$key}[$second]->column;
#       printf "Remote pair: boxes   for the cells are %d and %d.\n", $pairs->{$key}[$first]->box,    $pairs->{$key}[$second]->box;
        next if ( $pairs->{$key}[$first]->row    == $pairs->{$key}[$second]->row );
#       print "passed rows.\n";
        next if ( $pairs->{$key}[$first]->column == $pairs->{$key}[$second]->column );
#       print "passed columns.\n";
        next if ( $pairs->{$key}[$first]->box    == $pairs->{$key}[$second]->box );
#       printf "Remote pair: they are in fact 'remote'.\n";
        my $cell;
        # these two cells are now determined to be remote, ie having no cluster in common
        my $row1 = $pairs->{$key}[$first]->row;
        my $col1 = $pairs->{$key}[$first]->column;
        my $row2 = $pairs->{$key}[$second]->row;
        my $col2 = $pairs->{$key}[$second]->column;
        my ( $pair1, $pair2 ) = ( $key =~ /(\d)(\d)/ );
        # remove both possible values in the pair from both intersecting cells
        # at ( row1, col2 ) and ( row2 , col1 )
        foreach my $cell (
          $grid->cell_from_row_column( $row1, $col2 ),
          $grid->cell_from_row_column( $row2, $col1 )
        ) {
#         printf "Remote pair %d, %d will be removed from cell ( %d, %d, %d ).\n"
#                , $pair1
#                , $pair2
#                , ( $cell->row + 1 )
#                , ( $cell->column + 1 )
#                , ( $cell->box + 1 );
          # Is this cell also on the list of pairs.  If so, skip this one.
          next if ( scalar ( grep { $_ == $cell } ( @{ $pairs->{$key} } ) ) );
          # if $pair1 is still possible in this cell, remove it.
          if ( $cell->possibilities->[$pair1] ) {
            printf "Remote pair %d will be removed from cell ( %d, %d, %d ).\n"
                   , $pair1
                   , ( $cell->row + 1 )
                   , ( $cell->column + 1 )
                   , ( $cell->box + 1 );
              $cell->possibilities->[$pair1] = 0;
              $cell->possibilities->[0] = $cell->possibilities->[0] - 1;
              $progress++;
          }
          # if $pair2 is still possible in this cell, remove it.
          if ( $cell->possibilities->[$pair2] ) {
            printf "Remote pair %d will be removed from cell ( %d, %d, %d ).\n"
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
  print "Found and processed $progress cells this remote pair search pass.\n\n";
  return $progress;
}

1;
