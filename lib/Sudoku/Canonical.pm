package Sudoku::Canonical;

use strict;
use warnings;

use Exporter qw(import);

use Sudoku::Canonical::Result;
use Sudoku::CoordinateEncoding qw(validate_puzzle_string);
use Sudoku::Symmetry;

our @EXPORT_OK = qw(normalize_digits);

sub normalize_digits {
    my ($puzzle) = @_;
    return __PACKAGE__->digit_normal_form($puzzle)->puzzle;
}

sub digit_normal_form {
    my ($class, $puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my %mapping;
    my $next_target = 1;

    for my $digit (split //, $puzzle) {
        next if $digit eq '0' || exists $mapping{$digit};
        $mapping{$digit} = $next_target++;
    }

    # Complete the mapping so the recorded transform remains a full,
    # invertible digit permutation even when the puzzle omits some digits.
    for my $source_digit (1 .. 9) {
        next if exists $mapping{$source_digit};
        $mapping{$source_digit} = $next_target++;
    }

    my @digits = map { $mapping{$_} } 1 .. 9;
    my $transform = Sudoku::Symmetry->new(digits => \@digits);
    my $normalized = $transform->apply_puzzle($puzzle);

    return Sudoku::Canonical::Result->new(
        puzzle   => $normalized,
        transform => $transform,
        stage    => 'digit-normal',
    );
}

1;
