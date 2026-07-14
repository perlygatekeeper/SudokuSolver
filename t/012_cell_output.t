#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Cell;

sub capture_stdout (&) {
    my ($code) = @_;
    my $output = '';

    open my $stdout, '>', \$output
        or die "Could not open scalar stdout handle: $!";

    local *STDOUT = $stdout;
    $code->();

    return $output;
}

my $given = Cell->new(row => 0, column => 1, box => 2);
$given->clue(7);

my $given_output = capture_stdout { $given->show_my_possibilities };
like($given_output, qr/Cell at \( 1, 2, 3 \)/, 'show_my_possibilities prints one-based coordinates');
like($given_output, qr/Given:\s+7/, 'show_my_possibilities identifies given cells');

my $empty = Cell->new(row => 3, column => 4, box => 5);
$empty->clue('.');
$empty->remove_possibility(5);

my $empty_output = capture_stdout { $empty->show_my_possibilities };
like($empty_output, qr/Cell at \( 4, 5, 6 \)/, 'show_my_possibilities prints coordinates for unsolved cells');
like($empty_output, qr/Possibilities left: 8 ->/, 'show_my_possibilities prints possibility count');
like($empty_output, qr/Possibilities left: 8 -> 1, 2, 3, 4, 6, 7, 8, 9/, 'removed possibilities are not printed',);

my $solved = Cell->new(row => 6, column => 7, box => 8);
$solved->clue('.');
$solved->value(9);

my $solved_output = capture_stdout { $solved->show_my_possibilities };
like($solved_output, qr/Solved:\s+9/, 'show_my_possibilities identifies solved non-given cells');

done_testing();
