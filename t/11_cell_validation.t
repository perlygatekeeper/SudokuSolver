#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Cell;

my $cell = Cell->new;

for my $value (0 .. 9) {
    eval { $cell->value($value) };
    is($@, '', "CellValue accepts value $value");
    is($cell->value, $value, "value accessor stores $value");
}

for my $attribute (qw(row column box)) {
    for my $value (0 .. 9) {
        eval { $cell->$attribute($value) };
        is($@, '', "$attribute accepts CellValue $value");
        is($cell->$attribute, $value, "$attribute accessor stores $value");
    }

    eval { $cell->$attribute(10) };
    like($@, qr/not an integer between 0 and 9/, "$attribute rejects values greater than 9");

    eval { $cell->$attribute(-1) };
    like($@, qr/not an integer between 0 and 9/, "$attribute rejects negative values");
}

for my $bad_value (-1, 10) {
    eval { $cell->value($bad_value) };
    like($@, qr/not an integer between 0 and 9/, "value rejects $bad_value");
}

done_testing();
