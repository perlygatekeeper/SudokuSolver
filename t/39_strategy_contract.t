#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Sudoku::Strategy;

my @strategy_classes = Sudoku::Strategy->ordered_strategy_classes;

ok(@strategy_classes, 'strategy registry returns strategy classes');

for my $class (@strategy_classes) {
    use_ok($class);

    my $strategy = $class->new;
    isa_ok($strategy, 'Sudoku::Strategy::Base');
    can_ok($strategy, qw(name apply));

    (my $path = $class) =~ s{::}{/}g;
    $path = "lib/$path.pm";

    ok(-f $path, "$class source file exists at $path");

    open my $fh, '<', $path or die "Could not open $path: $!";
    my $source = do { local $/; <$fh> };
    close $fh;

    unlike(
        $source,
        qr/^\s*(?:print|printf)\b/m,
        "$class does not print directly",
    );

    unlike(
        $source,
        qr/->\s*value\s*\(/,
        "$class does not set cell values directly",
    );

    unlike(
        $source,
        qr/->\s*remove_possibility\s*\(/,
        "$class does not remove candidates directly",
    );

    unlike(
        $source,
        qr/->\s*possibilities\s*\(/,
        "$class does not replace candidate arrays directly",
    );

    unlike(
        $source,
        qr/->\s*possibilities->\[[^\]\n]+\]\s*=[^=]/,
        "$class does not mutate candidate array slots directly",
    );
}

done_testing();
