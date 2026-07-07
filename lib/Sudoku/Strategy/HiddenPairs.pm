package Sudoku::Strategy::HiddenPairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Hidden Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my $progress = 0;
  my $pairs;
  print "Looking for Hidden Pairs, (any two candidate values which exist \n";
  print "only in the same two cells in a given cluster):\n";
  my $possibility_counts = $grid->possibilities_hash;
# { # DEBUG
#   print "---- find_hidden_pairs: Start all possibility counts ------\n";
#   printf "%d %s\n", scalar( @{ $possibility_counts->{$_} } ), $_ foreach ( sort grep { $_=~/col6/ } keys %{ $possibility_counts } );
#   print "---- find_hidden_pairs: End   all possibility counts ------\n";
# }

  # Box examination
  $pairs = [ sort grep { $_ =~ /box/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  # pairs holds keys representing candidate values that are present only twice in a given box
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) { # from first to next-to-last
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) { # from one after first to last
      my( $box1, $box2, $value1, $value2, $cell1, $cell2 );
      ( $box1, $value1 ) = ( $pairs->[$first]  =~ /box(\d):(\d)/ );
      ( $box2, $value2 ) = ( $pairs->[$second] =~ /box(\d):(\d)/ );
      next if ( $box1 != $box2 );
      printf "Hidden pair (box): comparing candadate values %s and %s.\n", $pairs->[$first], $pairs->[$second];
      next if ( $possibility_counts->{$pairs->[$first] }[0]->row    != $possibility_counts->{$pairs->[$second]}[0]->row );
      next if ( $possibility_counts->{$pairs->[$first] }[0]->column != $possibility_counts->{$pairs->[$second]}[0]->column );
      print "Two candidate values shared first cell.\n";
      next if ( $possibility_counts->{$pairs->[$first] }[1]->row    != $possibility_counts->{$pairs->[$second]}[1]->row );
      next if ( $possibility_counts->{$pairs->[$first] }[1]->column != $possibility_counts->{$pairs->[$second]}[1]->column );
      print "Two candidate values shared second cell!  We have a pair.\n";
      # two cells are the same for value1 and value2
      $cell1 = $possibility_counts->{$pairs->[$first] }[0];
      $cell2 = $possibility_counts->{$pairs->[$first] }[1];
      if ( $cell1->possibilities->[0] > 2 ) { # first cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          print "Hidden pair (box): processing fist cell: candidate value $value?\n";
          next if ( $value == $value1 or $value == $value2 );
          print "Hidden pair (box): processing fist cell: Remove it!\n";
          # remove all others
          $cell1->remove_possibility($value);
        }
        print "Removed all other candidate values from first cell.\n";
      }
      if ( $cell2->possibilities->[0] > 2 ) { # second cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          next if ( $value == $value1 or $value == $value2 );
          # remove all others
          $cell2->remove_possibility($value);
        }
        print "Removed all other candidate values from second cell.\n";
      }
    }
  }

  # Row examination
  $pairs = [ sort grep { $_ =~ /row/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  # pairs holds keys representing candidate values that are present only twice in a given row
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) {         # from first to next-to-last
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) { # from one after first to last
      my( $row1, $row2, $value1, $value2, $cell1, $cell2 );
      ( $row1, $value1 ) = ( $pairs->[$first]  =~ /row(\d):(\d)/ );
      ( $row2, $value2 ) = ( $pairs->[$second] =~ /row(\d):(\d)/ );
      next if ( $row1 != $row2 );
      printf "Hidden pair (row): comparing candadate values %s and %s.\n", $pairs->[$first], $pairs->[$second];
      next if ( $possibility_counts->{$pairs->[$first] }[0]->column != $possibility_counts->{$pairs->[$second]}[0]->column );
      print "Two candidate values shared first cell.\n";
      next if ( $possibility_counts->{$pairs->[$first] }[1]->column != $possibility_counts->{$pairs->[$second]}[1]->column );
      print "Two candidate values shared second cell!  We have a pair.\n";
      # two cells are the same for value1 and value2
      $cell1 = $possibility_counts->{$pairs->[$first] }[0];
      $cell2 = $possibility_counts->{$pairs->[$first] }[1];
      if ( $cell1->possibilities->[0] > 2 ) { # first cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          print "Hidden pair (row): processing fist cell: candidate value $value?\n";
          next if ( $value == $value1 or $value == $value2 );
          print "Hidden pair (row): processing fist cell: Remove it!\n";
          # remove all others
          $cell1->remove_possibility($value);
        }
        print "Removed all other candidate values from first cell.\n";
      }
      if ( $cell2->possibilities->[0] > 2 ) { # second cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          next if ( $value == $value1 or $value == $value2 );
          # remove all others
          $cell2->remove_possibility($value);
        }
        print "Removed all other candidate values from second cell.\n";
      }
    }
  }

  # Column examination
  $pairs = [ sort grep { $_ =~ /col/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  # pairs holds keys representing candidate values that are present only twice in a given column
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) {         # from first to next-to-last
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) { # from one after first to last
      my( $col1, $col2, $value1, $value2, $cell1, $cell2 );
      ( $col1, $value1 ) = ( $pairs->[$first]  =~ /col(\d):(\d)/ );
      ( $col2, $value2 ) = ( $pairs->[$second] =~ /col(\d):(\d)/ );
      next if ( $col1 != $col2 );
      printf "Hidden pair (col): comparing candadate values %s and %s.\n", $pairs->[$first], $pairs->[$second];
      next if ( $possibility_counts->{$pairs->[$first] }[0]->row != $possibility_counts->{$pairs->[$second]}[0]->row );
      print "Two candidate values shared first cell.\n";
      next if ( $possibility_counts->{$pairs->[$first] }[1]->row != $possibility_counts->{$pairs->[$second]}[1]->row );
      print "Two candidate values shared second cell!  We have a pair.\n";
      # two cells are the same for value1 and value2
      $cell1 = $possibility_counts->{$pairs->[$first] }[0];
      $cell2 = $possibility_counts->{$pairs->[$first] }[1];
      if ( $cell1->possibilities->[0] > 2 ) { # first cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          print "Hidden pair (col): processing fist cell: candidate value $value?\n";
          next if ( $value == $value1 or $value == $value2 );
          print "Hidden pair (col): processing fist cell: Remove it!\n";
          # remove all others
          $cell1->remove_possibility($value);
        }
        print "Removed all other candidate values from first cell.\n";
      }
      if ( $cell2->possibilities->[0] > 2 ) { # second cell of this pair of candidate values have other candidate values
        foreach my $value ( grep { $_ } @{ $cell1->possibilities }[1..9] ) {
          next if ( $value == $value1 or $value == $value2 );
          # remove all others
          $cell2->remove_possibility($value);
        }
        print "Removed all other candidate values from second cell.\n";
      }
    }
  }

  print "Found and processed $progress hidden pairs.\n\n";
  return $progress;
}

1;
