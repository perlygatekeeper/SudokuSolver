package Sudoku::Canonical;

use strict;
use warnings;

use Exporter qw(import);

use Sudoku::Canonical::Result;
use Sudoku::CoordinateEncoding qw(validate_puzzle_string);
use Sudoku::Symmetry;

our @EXPORT_OK = qw(normalize_digits normalize_rows normalize_columns);

sub normalize_digits {
    my ($puzzle) = @_;
    return __PACKAGE__->digit_normal_form($puzzle)->puzzle;
}

sub normalize_rows {
    my ($puzzle) = @_;
    return __PACKAGE__->row_normal_form($puzzle)->puzzle;
}

sub normalize_columns {
    my ($puzzle) = @_;
    return __PACKAGE__->column_normal_form($puzzle)->puzzle;
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

sub row_normal_form {
    my ($class, $puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my $best;

    for my $bands (_permutations([ 0 .. 2 ])) {
        for my $rows0 (_permutations([ 0 .. 2 ])) {
            for my $rows1 (_permutations([ 0 .. 2 ])) {
                for my $rows2 (_permutations([ 0 .. 2 ])) {
                    my $spatial = Sudoku::Symmetry->new(
                        bands => $bands,
                        rows  => [ $rows0, $rows1, $rows2 ],
                    );

                    my $moved = $spatial->apply_puzzle($puzzle);
                    my $digit = $class->digit_normal_form($moved);
                    my $combined = $spatial->compose($digit->transform);

                    next if defined $best && $digit->puzzle ge $best->puzzle;

                    $best = Sudoku::Canonical::Result->new(
                        puzzle    => $digit->puzzle,
                        transform => $combined,
                        stage     => 'row-normal',
                    );
                }
            }
        }
    }

    return $best;
}

sub column_normal_form {
    my ($class, $puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my $best;

    for my $stacks (_permutations([ 0 .. 2 ])) {
        for my $cols0 (_permutations([ 0 .. 2 ])) {
            for my $cols1 (_permutations([ 0 .. 2 ])) {
                for my $cols2 (_permutations([ 0 .. 2 ])) {
                    my $spatial = Sudoku::Symmetry->new(
                        stacks => $stacks,
                        cols   => [ $cols0, $cols1, $cols2 ],
                    );

                    my $moved = $spatial->apply_puzzle($puzzle);
                    my $digit = $class->digit_normal_form($moved);
                    my $combined = $spatial->compose($digit->transform);

                    next if defined $best && $digit->puzzle ge $best->puzzle;

                    $best = Sudoku::Canonical::Result->new(
                        puzzle    => $digit->puzzle,
                        transform => $combined,
                        stage     => 'column-normal',
                    );
                }
            }
        }
    }

    return $best;
}

sub _permutations {
    my ($values) = @_;
    my @results;
    _permute([], [ @$values ], \@results);
    return @results;
}

sub _permute {
    my ($prefix, $remaining, $results) = @_;

    if (!@$remaining) {
        push @$results, [ @$prefix ];
        return;
    }

    for my $index (0 .. $#$remaining) {
        my @next_remaining = @$remaining;
        my $value = splice @next_remaining, $index, 1;
        _permute([ @$prefix, $value ], \@next_remaining, $results);
    }
}

1;
