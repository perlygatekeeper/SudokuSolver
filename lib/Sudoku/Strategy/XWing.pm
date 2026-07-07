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
  my @deductions;
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
    }
    print "xwing_candidates: ( $xwing_candidates) \n";
    foreach my $value ( grep { scalar( @{$xwing_candidates->{$_}} ) >= 2 } keys %{ $xwing_candidates } ) {
      printf "X-wing (column-based): processing value $value,  " if ($debug);
      printf "which has %d columns where it appears as a candidate only twice.\n", scalar( @{ $xwing_candidates->{$value} } ) if ($debug);
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) {
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) {
          my $first_column  = $xwing_candidates->{$value}[$first];
          my $second_column = $xwing_candidates->{$value}[$second];
          if ($debug) {
              printf "Examining columns %d and %d.\n", 1 + $first_column, 1 + $second_column;
          }
          my $row_count = {};
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $first_column  . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $second_column . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          if ( scalar( keys %$row_count ) == 2 ) {
            if ($debug) {
              printf "We have found a column-based X-wing for $value, involving columns %d and %d and rows %d and %d!\n",
                     1 + $first_column,
                     1 + $second_column,
                     map { 1 + $_ } keys %$row_count;
            }
            $x_wings++;
            foreach my $row ( keys %$row_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'row' . $row . ':' . $value } } ) {
                next if ( $cell->column == $first_column or $cell->column == $second_column );
                if ($debug) {
                  printf "X-wing column-based: removal of %d from cell at ( %d, %d )\n",
                         $value,
                         1 + $row,
                         1 + $cell->column;
                }
                push @deductions, $self->_remove_candidate_deduction(
                  $cell,
                  $value,
                  sprintf('X-wing column-based removes %d from cell at ( %d, %d ).', $value, 1 + $row, 1 + $cell->column),
                );
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
    }
    foreach my $value ( grep { scalar( @{$xwing_candidates->{$_}} ) >= 2 } keys %{ $xwing_candidates } ) {
      printf "X-wing (row-based): processing value $value,  " if ($debug);
      printf "which has %d rows where it appears as a candidate only twice.\n", scalar( @{ $xwing_candidates->{$value} } ) if ($debug);
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) {
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) {
          my $first_row  = $xwing_candidates->{$value}[$first];
          my $second_row = $xwing_candidates->{$value}[$second];
          if ($debug) {
              printf "Examining rows %d and %d.\n", 1 + $first_row, 1 + $second_row;
          }
          my $column_count = {};
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $first_row  . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $second_row . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          if ( scalar( keys %$column_count ) == 2 ) {
            if ($debug) {
              printf "We have found a row-based X-wing for $value, involving rows %d and %d and columns %d and %d!\n",
                     1 + $first_row,
                     1 + $second_row,
                     map { 1 + $_ } keys %$column_count;
            }
            $x_wings++;
            foreach my $column ( keys %$column_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'col' . $column . ':' . $value } } ) {
                next if ( $cell->row == $first_row or $cell->row == $second_row );
                if ($debug) {
                  printf "X-wing row-based: removal of %d from cell at ( %d, %d )\n",
                         $value,
                         1 + $cell->row,
                         1 + $column;
                }
                push @deductions, $self->_remove_candidate_deduction(
                  $cell,
                  $value,
                  sprintf('X-wing row-based removes %d from cell at ( %d, %d ).', $value, 1 + $cell->row, 1 + $column),
                );
              }
            }
          }
        }
      }
    }
  } else {
    print "Found no row-based pair possibilities.\n";
  }

  print 'Found and processed ' . $x_wings . ' X-Wings which resulted in ' . scalar(@deductions) . " candidates being removed.\n\n";
  return @deductions;
}

1;
