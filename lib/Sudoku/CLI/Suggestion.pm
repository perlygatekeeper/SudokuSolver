package Sudoku::CLI::Suggestion;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(suggest_value);

sub suggest_value {
    my (%args) = @_;

    my $input   = $args{input};
    my $choices = $args{choices};

    return if !defined $input;
    return if ref($choices) ne 'ARRAY' || !@$choices;

    my $normalized_input = _normalize($input);
    return if $normalized_input eq q{};

    my ($best, $best_distance, $best_length_delta);

    for my $choice (@$choices) {
        next if !defined $choice;

        my $normalized_choice = _normalize($choice);
        my $distance = _damerau_levenshtein($normalized_input, $normalized_choice);
        my $length_delta = abs(length($normalized_input) - length($normalized_choice));

        if (
            !defined $best_distance
            || $distance < $best_distance
            || ($distance == $best_distance && $length_delta < $best_length_delta)
            || ($distance == $best_distance && $length_delta == $best_length_delta && $choice lt $best)
        ) {
            $best = $choice;
            $best_distance = $distance;
            $best_length_delta = $length_delta;
        }
    }

    return if !defined $best;
    return if !_reasonable_match($normalized_input, _normalize($best), $best_distance);

    return $best;
}

sub _normalize {
    my ($value) = @_;
    $value = lc($value // q{});
    $value =~ tr/_/-/;
    $value =~ s/\s+/-/g;
    $value =~ s/-+/-/g;
    return $value;
}

sub _reasonable_match {
    my ($input, $choice, $distance) = @_;

    my $longest = length($input) > length($choice)
        ? length($input)
        : length($choice);

    return 1 if $distance <= 1;
    return 1 if $longest >= 5 && $distance <= 2;
    return 1 if $longest >= 9 && $distance <= 3;

    return 0;
}

sub _damerau_levenshtein {
    my ($left, $right) = @_;

    my @left  = split //, $left;
    my @right = split //, $right;

    return scalar @right if !@left;
    return scalar @left  if !@right;

    my @matrix;
    $matrix[0][$_] = $_ for 0 .. @right;
    $matrix[$_][0] = $_ for 0 .. @left;

    for my $i (1 .. @left) {
        for my $j (1 .. @right) {
            my $cost = $left[$i - 1] eq $right[$j - 1] ? 0 : 1;

            my $value = _minimum(
                $matrix[$i - 1][$j] + 1,
                $matrix[$i][$j - 1] + 1,
                $matrix[$i - 1][$j - 1] + $cost,
            );

            if (
                $i > 1
                && $j > 1
                && $left[$i - 1] eq $right[$j - 2]
                && $left[$i - 2] eq $right[$j - 1]
            ) {
                $value = _minimum($value, $matrix[$i - 2][$j - 2] + 1);
            }

            $matrix[$i][$j] = $value;
        }
    }

    return $matrix[@left][@right];
}

sub _minimum {
    my $minimum = shift;
    for my $value (@_) {
        $minimum = $value if $value < $minimum;
    }
    return $minimum;
}

1;
