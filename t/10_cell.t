#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Cell;

my $given = Cell->new;
$given->clue(5);

is($given->given, 1, 'clue marks a digit cell as given');
is($given->value, 5, 'clue stores the given digit as the cell value');
is_deeply(
    $given->possibilities,
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    'given cells have no remaining possibilities',
);

my $empty = Cell->new;
$empty->clue('.');

is($empty->given, 0, 'non-digit clue creates an ungiven cell');
is($empty->value, 0, 'non-digit clue leaves the cell unsolved');
is_deeply(
    $empty->possibilities,
    [ 9, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
    'unsolved cells start with nine possibilities',
);

is($empty->remove_possibility(5), 1, 'remove_possibility removes an available candidate');
is($empty->possibilities->[5], 0, 'removed candidate is cleared');
is($empty->possibilities->[0], 8, 'possibility count is decremented');

is($empty->remove_possibility(5), 0, 'remove_possibility ignores an already removed candidate');
is($empty->possibilities->[0], 8, 'possibility count is not decremented twice');

is($given->remove_possibility(5), 0, 'remove_possibility ignores solved cells');
is_deeply(
    $given->possibilities,
    [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
    'solved cell possibilities remain unchanged',
);

done_testing();
