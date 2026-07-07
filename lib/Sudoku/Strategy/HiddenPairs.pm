package Sudoku::Strategy::HiddenPairs;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Hidden Pairs';
}

sub apply {
  my ($self, $grid) = @_;
  my @deductions;
  my %seen;
  my $pairs;
  print "Looking for Hidden Pairs, (any two candidate values which exist \n";
  print "only in the same two cells in a given cluster):\n";
  my $possibility_counts = $grid->possibilities_hash;

  # Box examination
  $pairs = [ sort grep { $_ =~ /box/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) {
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) {
      my( $box1, $box2, $value1, $value2 );
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
      push @deductions, $self->_hidden_pair_deductions(
        $possibility_counts->{$pairs->[$first] }[0],
        $possibility_counts->{$pairs->[$first] }[1],
        $value1,
        $value2,
        \%seen,
        sprintf('Hidden pair in box %d keeps only %d and %d.', $box1 + 1, $value1, $value2),
      );
    }
  }

  # Row examination
  $pairs = [ sort grep { $_ =~ /row/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) {
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) {
      my( $row1, $row2, $value1, $value2 );
      ( $row1, $value1 ) = ( $pairs->[$first]  =~ /row(\d):(\d)/ );
      ( $row2, $value2 ) = ( $pairs->[$second] =~ /row(\d):(\d)/ );
      next if ( $row1 != $row2 );
      printf "Hidden pair (row): comparing candadate values %s and %s.\n", $pairs->[$first], $pairs->[$second];
      next if ( $possibility_counts->{$pairs->[$first] }[0]->column != $possibility_counts->{$pairs->[$second]}[0]->column );
      print "Two candidate values shared first cell.\n";
      next if ( $possibility_counts->{$pairs->[$first] }[1]->column != $possibility_counts->{$pairs->[$second]}[1]->column );
      print "Two candidate values shared second cell!  We have a pair.\n";
      push @deductions, $self->_hidden_pair_deductions(
        $possibility_counts->{$pairs->[$first] }[0],
        $possibility_counts->{$pairs->[$first] }[1],
        $value1,
        $value2,
        \%seen,
        sprintf('Hidden pair in row %d keeps only %d and %d.', $row1 + 1, $value1, $value2),
      );
    }
  }

  # Column examination
  $pairs = [ sort grep { $_ =~ /col/ and scalar( @{ $possibility_counts->{$_} } ) == 2 } keys %{ $possibility_counts } ];
  foreach my $first ( 0 .. ( $#{$pairs} - 1 ) ) {
    foreach my $second ( ( $first + 1 ) .. $#{$pairs} ) {
      my( $col1, $col2, $value1, $value2 );
      ( $col1, $value1 ) = ( $pairs->[$first]  =~ /col(\d):(\d)/ );
      ( $col2, $value2 ) = ( $pairs->[$second] =~ /col(\d):(\d)/ );
      next if ( $col1 != $col2 );
      printf "Hidden pair (col): comparing candadate values %s and %s.\n", $pairs->[$first], $pairs->[$second];
      next if ( $possibility_counts->{$pairs->[$first] }[0]->row != $possibility_counts->{$pairs->[$second]}[0]->row );
      print "Two candidate values shared first cell.\n";
      next if ( $possibility_counts->{$pairs->[$first] }[1]->row != $possibility_counts->{$pairs->[$second]}[1]->row );
      print "Two candidate values shared second cell!  We have a pair.\n";
      push @deductions, $self->_hidden_pair_deductions(
        $possibility_counts->{$pairs->[$first] }[0],
        $possibility_counts->{$pairs->[$first] }[1],
        $value1,
        $value2,
        \%seen,
        sprintf('Hidden pair in column %d keeps only %d and %d.', $col1 + 1, $value1, $value2),
      );
    }
  }

  print 'Found and processed ' . scalar(@deductions) . " hidden pairs.\n\n";
  return @deductions;
}

sub _hidden_pair_deductions {
  my ( $self, $cell1, $cell2, $value1, $value2, $seen, $reason ) = @_;

  my @deductions;
  my %keep = map { $_ => 1 } ( $value1, $value2 );

  for my $cell ( $cell1, $cell2 ) {
    next unless $cell->possibilities->[0] > 2;
    for my $value ( grep { $_ } @{ $cell->possibilities }[1..9] ) {
      next if $keep{$value};
      my $key = join q{:}, $cell->row, $cell->column, $value;
      next if $seen->{$key}++;
      push @deductions, $self->_remove_candidate_deduction( $cell, $value, $reason );
    }
  }

  return @deductions;
}

1;
