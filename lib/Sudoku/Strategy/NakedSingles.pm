package Sudoku::Strategy::NakedSingles;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

sub name {
    return 'Naked Singles';
}

sub apply {
    my ($self, $grid) = @_;

    my $progress = 0;

    print "Looking for Singletons\n";

    for my $cell (@{ $grid->cells }) {
        next if $cell->value;
        next unless $cell->possibilities->[0] == 1;

        my ($value) = grep { $cell->possibilities->[$_] } 1 .. 9;
        next unless $value;

        $cell->value($value);
        $cell->possibilities([ (0) x 10 ]);

        $grid->solved(1 + $grid->solved);
        $grid->remove_my_solution_from_my_mates($cell);

        $progress++;
    }

    return $progress;
}

1;
