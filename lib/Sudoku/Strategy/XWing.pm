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
  my @deductions;
  my ( $pairs, $value );
  my ( $row, $column );
  my $xwing_candidates;

  # COLUMNS
  my $possibility_counts = $grid->possibilities_hash;
  $pairs = [ grep { $_ =~ /col/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  if ( scalar @$pairs ) {
    foreach my $key ( @$pairs ) {
      ( $column, $value )  = ( $key =~ /col(\d):(\d)/ );
      push ( @{ $xwing_candidates->{$value} } , $column );
    }
    foreach my $value ( grep { scalar( @{$xwing_candidates->{$_}} ) >= 2 } keys %{ $xwing_candidates } ) {
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) {
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) {
          my $first_column  = $xwing_candidates->{$value}[$first];
          my $second_column = $xwing_candidates->{$value}[$second];
          my $row_count = {};
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $first_column  . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          foreach my $cell ( @{ $possibility_counts->{ 'col' . $second_column . ':' . $value } } ) {
            $row_count->{ $cell->row }++;
          }
          if ( scalar( keys %$row_count ) == 2 ) {
            $x_wings++;
            foreach my $row ( keys %$row_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'row' . $row . ':' . $value } } ) {
                next if ( $cell->column == $first_column or $cell->column == $second_column );
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
      foreach my $first    ( 0               ..  ( $#{$xwing_candidates->{$value}} - 1 ) ) {
        foreach my $second ( ( $first + 1 )  ..  $#{$xwing_candidates->{$value}}         ) {
          my $first_row  = $xwing_candidates->{$value}[$first];
          my $second_row = $xwing_candidates->{$value}[$second];
          my $column_count = {};
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $first_row  . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          foreach my $cell ( @{ $possibility_counts->{ 'row' . $second_row . ':' . $value } } ) {
            $column_count->{ $cell->column }++;
          }
          if ( scalar( keys %$column_count ) == 2 ) {
            $x_wings++;
            foreach my $column ( keys %$column_count ) {
              foreach my $cell ( @{ $possibility_counts->{ 'col' . $column . ':' . $value } } ) {
                next if ( $cell->row == $first_row or $cell->row == $second_row );
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
  }

  return @deductions;
}

1;
