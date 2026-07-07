package Sudoku::Strategy::XWing;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'X-Wing';
}

sub apply {
  my ($self, $grid) = @_;
  my $x_wings = 0;
  my $debug = 1;
  my $progress = 0;
  my ( $pairs, $value );
  my ( $row, $column );
  my $xwing_candidates;
  print "Looking for X-Wings, any 4 cells with the same possible value\n";
  print "that are only candidates in two cells of a given column or row and\n";
  print "involve the same two rows or columns respectively, thus forming an X:\n";

  # COLUMNS
  my $possibility_counts = $grid->possibilities_hash;
  $pairs = [ grep { $_ =~ /col/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  print "#pairs ( " . scalar @$pairs . " ) \n";
  if ( scalar @$pairs ) {
    foreach my $key ( @$pairs ) {
      ( $column, $value )  = ( $key =~ /col(\d):(\d)/ );
      push ( @{ $xwing_candidates->{$value} } , $column );
      # $xwing_candidates->{ value is 4 } is array with all columns where it appears only twice
    }
    print "xwing_candidates: ( $xwing_candidates) \n";
    # loop over all values which have 2 or more columns where this value only appears twice as a candidate
    # for each pair of such columns see if this value forms an x-wing
    foreach my $value ( grep { scalar( @{$xwing_candidates->{$_}} ) >= 2 } keys %{ $xwing_candidates } ) {
      printf "X-wing (column-based): processing value $value,  " if ($debug);
      printf "which has %d columns where it appears as a candidate only twice.\n", scalar( @{ $xwing_candidates->{$value} } ) if ($debug);
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) { # from first to next-to-last
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) { # from one after first to last
          my $first_column  = $xwing_candidates->{$value}[$first];
          my $second_column = $xwing_candidates->{$value}[$second];
          if ($debug) {
              printf "Examining columns %d and %d.\n"
                     , 1 + $first_column
                     , 1 + $second_column;
          }
          # I have a pair of columns for which $value shows up only twice as a candidate
          # if they happen to be in the same two rows, this will form an X-Wing and this value may be removed
          # from all other cells in the two rows which aren't part of the x-wing, see X-Wing strategy notes
          # for more information.
          my $row_count = {};
          # process the 2 cells in the first column, noting the row in which they reside
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $first_column  . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          # process the 2 cells in the second column, noting the row in which they reside
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $second_column . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          if ( scalar ( keys( %$row_count )  )  == 2 ) {
            if ($debug) {
              printf "We have found a column-based X-wing for $value, involving columns %d and %d and rows %d and %d!\n"
                     , 1 + $first_column
                     , 1 + $second_column
                     , map { 1 + $_ } keys %$row_count;
            }
            $x_wings++;
            foreach my $row ( keys %$row_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'row' . $row . ':' . $value } } ) {
                next if ( $cell->column == $first_column or $cell->column == $second_column );
                if ($debug) {
                  printf "X-wing column-based: removal of %d from cell at ( %d, %d )\n"
                         , $value
                         , 1 + $row
                         , 1 + $cell->column;
                }
                $progress += $cell->remove_possibility($value);
              }
            }
          }
        }
      }
    }
  } else {
    print "Found no row-based pair possibilities.\n";
  }

  # ROWS
  $xwing_candidates = {};
  $possibility_counts = $grid->possibilities_hash;
  $pairs = [ grep { $_ =~ /row/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  if ( scalar @$pairs ) {
    foreach my $key ( @$pairs ) {
      ( $row, $value )  = ( $key =~ /row(\d):(\d)/ );
      push ( @{ $xwing_candidates->{$value} } , $row );
      # $xwing_candidates->{ value is 4 } is array with all rows where it appears only twice
    }
    # loop over all values which have 2 or more rows where this value only appears twice as a candidate
    # for each pair of such rows see if this value forms an x-wing
    foreach my $value ( grep { scalar( @{$xwing_candidates->{$_}} ) >= 2 } keys %{ $xwing_candidates } ) {
      printf "X-wing (row-based): processing value $value,  " if ($debug);
      printf "which has %d rows where it appears as a candidate only twice.\n", scalar( @{ $xwing_candidates->{$value} } ) if ($debug);
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) { # from first to next-to-last
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) { # from one after first to last
          my $first_row  = $xwing_candidates->{$value}[$first];
          my $second_row = $xwing_candidates->{$value}[$second];
          if ($debug) {
              printf "Examining rows %d and %d.\n"
                     , 1 + $first_row
                     , 1 + $second_row;
          }
          # I have a pair of rows for which $value shows up only twice as a candidate
          # if they happen to be in the same two columns, this will form an X-Wing and this value may be removed
          # from all other cells in the two columns which aren't part of the x-wing.
          my $column_count = {};
          # process the 2 cells in the first column, noting the row in which they reside
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $first_row  . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          # process the 2 cells in the second column, noting the row in which they reside
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $second_row . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          if ( scalar ( keys( %$column_count )  )  == 2 ) {
            if ($debug) {
              printf "We have found a row-based X-wing for $value, involving rows %d and %d and columns %d and %d!\n"
                     , 1 + $first_row
                     , 1 + $second_row
                     , map { 1 + $_ } keys %$column_count;
            }
            $x_wings++;
            foreach my $column ( keys %$column_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'col' . $column . ':' . $value } } ) {
                next if ( $cell->row == $first_row or $cell->row == $second_row );
                if ($debug) {
                  printf "X-wing row-based: removal of %d from cell at ( %d, %d )\n"
                         , $value
                         , 1 + $cell->row
                         , 1 + $column;
                }
                $progress += $cell->remove_possibility($value);
              }
            }
          }
        }
      }
    }
  } else {
    print "Found no row-based pair possibilities.\n";
  }

  print "Found and processed $x_wings X-Wings which resulted in $progress candidates being removed.\n\n";
  return $progress;
}

1;
