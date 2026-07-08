package Sudoku::Strategy::NakedPairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Naked Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my @deductions;

  my $pairs = $grid->pairs_possible_by_cluster;

  foreach my $key ( grep { scalar( @{ $pairs->{$_} } ) == 2 } keys %{ $pairs } ) {
    if ( $key =~ /row/ ) {
      my ( $row, $pair1, $pair2 ) = ( $key =~ /row:(\d) -> (\d)(\d)/ );
      my $col1 = $pairs->{ $key }[0]->column;
      my $col2 = $pairs->{ $key }[1]->column;

      foreach my $cell ( grep { not $_->value } @{ $grid->rows->[$row] } ) {
        my $col = $cell->column;
        next if ( $col == $col1 or $col == $col2 );

        for my $value ( $pair1, $pair2 ) {
          next unless $cell->possibilities->[$value];
          my $reason = sprintf(
            'Naked pair in row %d, cols %d and %d leads to %d being removed from cell ( %d, %d, %d ).',
            $row + 1,
            $col1 + 1,
            $col2 + 1,
            $value,
            $cell->row + 1,
            $cell->column + 1,
            $cell->box + 1,
          );
          push @deductions, $self->_remove_candidate_deduction($cell, $value, $reason);
        }
      }
    }

    if ( $key =~ /col/ ) {
      my ( $col, $pair1, $pair2 ) = ( $key =~ /col:(\d) -> (\d)(\d)/ );
      my $row1 = $pairs->{ $key }[0]->row;
      my $row2 = $pairs->{ $key }[1]->row;

      foreach my $cell ( grep { not $_->value } @{ $grid->columns->[$col] } ) {
        my $row = $cell->row;
        next if ( $row == $row1 or $row == $row2 );

        for my $value ( $pair1, $pair2 ) {
          next unless $cell->possibilities->[$value];
          my $reason = sprintf(
            'Naked pair in col %d, rows %d and %d leads to %d being removed from cell ( %d, %d, %d ).',
            $col + 1,
            $row1 + 1,
            $row2 + 1,
            $value,
            $cell->row + 1,
            $cell->column + 1,
            $cell->box + 1,
          );
          push @deductions, $self->_remove_candidate_deduction($cell, $value, $reason);
        }
      }
    }

    if ( $key =~ /box/ ) {
      my ( $box, $pair1, $pair2 ) = ( $key =~ /box:(\d) -> (\d)(\d)/ );
      my $row1 = $pairs->{ $key }[0]->row;
      my $row2 = $pairs->{ $key }[1]->row;
      my $col1 = $pairs->{ $key }[0]->column;
      my $col2 = $pairs->{ $key }[1]->column;

      foreach my $cell ( grep { not $_->value } @{ $grid->boxes->[$box] } ) {
        my $row = $cell->row;
        my $col = $cell->column;
        next if ( ( $row == $row1 and $col == $col1 )
               or ( $row == $row2 and $col == $col2 ) );

        for my $value ( $pair1, $pair2 ) {
          next unless $cell->possibilities->[$value];
          my $reason = sprintf(
            'Naked pair in box %d, cells ( %d, %d ) and ( %d, %d ) leads to %d being removed from cell ( %d, %d, %d ).',
            $box + 1,
            $row1 + 1,
            $col1 + 1,
            $row2 + 1,
            $col2 + 1,
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

  return @deductions;
}

1;
