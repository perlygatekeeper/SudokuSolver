package Sudoku::Strategy::Base;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub name {
    die 'name() not implemented by strategy class';
}

sub apply {
    die 'apply($grid) not implemented by strategy class';
}

1;
