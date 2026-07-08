package Sudoku::Strategy::RemotePairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Remote Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my @deductions;
  my $pairs = $grid->pairs_possible;
  foreach my $key ( grep { scalar( @{ $pairs->{$_} } ) >= 2  } ( keys %{ $pairs } ) ) {
    foreach my $first ( 0 .. ( $#{$pairs->{$key}} - 1 ) ) {
      foreach my $second ( ( $first + 1 ) .. $#{$pairs->{$key}} ) {
        next if ( $pairs->{$key}[$first]->row    == $pairs->{$key}[$second]->row );
        next if ( $pairs->{$key}[$first]->column == $pairs->{$key}[$second]->column );
        next if ( $pairs->{$key}[$first]->box    == $pairs->{$key}[$second]->box );
        my $row1 = $pairs->{$key}[$first]->row;
        my $col1 = $pairs->{$key}[$first]->column;
        my $row2 = $pairs->{$key}[$second]->row;
        my $col2 = $pairs->{$key}[$second]->column;
        my ( $pair1, $pair2 ) = ( $key =~ /(\d)(\d)/ );
        foreach my $cell (
          $grid->cell_from_row_column( $row1, $col2 ),
          $grid->cell_from_row_column( $row2, $col1 )
        ) {
          next if ( scalar( grep { $_ == $cell } @{ $pairs->{$key} } ) );
          for my $value ( $pair1, $pair2 ) {
            next unless $cell->possibilities->[$value];
            my $reason = sprintf(
              'Remote pair %d will be removed from cell ( %d, %d, %d ).',
              $value,
              $cell->row + 1,
              $cell->column + 1,
              $cell->box + 1,
            );
            push @deductions, $self->_remove_candidate_deduction($cell, $value, $reason);
          }
        }
      }
    }
  }
  return @deductions;
}

1;
