package Cell;
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;
use Carp;

has 'given'       => (isa => 'Int',      is => 'rw');
has 'value'       => (isa => 'Value',    is => 'rw');
has 'possibilies' => (isa => 'ArrayRef', is => 'rw');
has 'row'         => (isa => 'Value',    is => 'rw');
has 'column'      => (isa => 'Value',    is => 'rw');
has 'box'         => (isa => 'Value',    is => 'rw');

# Methods

# All of these will be prameter to include only unsolved cells
# my_mates     all other cells in any of my row, column or box
# my_row_mates    all other cells in his cell's row
# my_column_mates all other cells in his cell's column
# my_box_mates    all other cells in his cell's box

sub clue {
    my($self,$value) = @_;
    if ( $value =~ /[1-9]/ ) {
       $self->given(1);
       $self->value($value);
       $self->possibilies( [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ] );
    } else {
       $self->given(0);
       $self->value(0);
       $self->possibilies( [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] );
    }
}; 

sub my_possibilies {
    my $self = shift;
    if ( $self->value ) {
      print "Possible: " . join( ', ', grep { $_ !=0 } @{$self->possibilies} ) . "\n";
    } else {
      if ( $self->given ) {
        print "Given:  " . $self->value . "\n";
      } else {
        print "Solved: " . $self->value . "\n";
      }
    }
}

sub my_mates        { # all other cells in any of my row, column or box
    my $self = shift;

}; 

sub my_row_mates    { # all other cells in his cell's row
    my $self = shift;
    $self->row;
    return [ ];

}; 

sub my_column_mates { # all other cells in his cell's column
    my $self = shift;

}; 

sub my_box_mates    { # all other cells in his cell's box
    my $self = shift;

}; 

# clear_my_value
# clear_my_value_from_my_row
# clear_my_value_from_my_column
# clear_my_value_from_my_box


1;
