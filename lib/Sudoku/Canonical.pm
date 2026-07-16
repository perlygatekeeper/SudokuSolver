package Sudoku::Canonical;

use strict;
use warnings;

use Exporter qw(import);

use Sudoku::Canonical::Result;
use Sudoku::CoordinateEncoding qw(encode_puzzle validate_puzzle_string);
use Sudoku::Symmetry;

our @EXPORT_OK = qw(
    normalize_digits
    normalize_rows
    normalize_columns
    canonicalize
    canonical_fingerprint
);

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

sub canonicalize {
    my ($puzzle) = @_;
    return __PACKAGE__->canonical_form($puzzle)->puzzle;
}

sub canonical_fingerprint {
    my ($puzzle) = @_;
    return encode_puzzle(canonicalize($puzzle));
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


sub canonical_form {
    my ($class, $puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my @source_rows = map { substr($puzzle, $_ * 9, 9) } 0 .. 8;
    my @row_specs = _spatial_specs('row');
    my @col_specs = _spatial_specs('column');

    # The canonical representative must have the lexicographically smallest
    # possible first row.  Determine that row before entering the full
    # row-family x column-family search, then retain only column transforms
    # capable of producing it for each possible source row.  This is exact
    # pruning: every discarded candidate already loses within its first nine
    # characters and therefore cannot be the global minimum.
    my ($best_first_row, %first_row_columns);
    for my $source_row_index (0 .. 8) {
        my $row = $source_rows[$source_row_index];
        for my $col_index (0 .. $#col_specs) {
            my $first_row = _normalized_row(
                $row,
                $col_specs[$col_index]{target_to_source},
            );

            if (!defined($best_first_row) || $first_row lt $best_first_row) {
                $best_first_row = $first_row;
                %first_row_columns = (
                    $source_row_index => [ $col_index ],
                );
            }
            elsif ($first_row eq $best_first_row) {
                push @{ $first_row_columns{$source_row_index} }, $col_index;
            }
        }
    }

    my $best_puzzle;
    my ($best_row_spec, $best_col_spec, $best_digits);

    for my $row_spec (@row_specs) {
        my $first_source_row = $row_spec->{target_to_source}[0];
        my $eligible_columns = $first_row_columns{$first_source_row} || next;
        my @rows = map { $source_rows[$_] } @{ $row_spec->{target_to_source} };

        for my $col_index (@$eligible_columns) {
            my $col_spec = $col_specs[$col_index];
            my @digit_map = (0) x 10;
            my $next_digit = 1;
            my $candidate = q{};
            my $lost = 0;

            for my $target_row (0 .. 8) {
                my $row = $rows[$target_row];
                for my $source_col (@{ $col_spec->{target_to_source} }) {
                    my $digit = substr($row, $source_col, 1);
                    if ($digit ne '0') {
                        $digit_map[$digit] ||= $next_digit++;
                        $digit = $digit_map[$digit];
                    }
                    $candidate .= $digit;

                    if (defined $best_puzzle) {
                        my $prefix_length = length $candidate;
                        if ($candidate gt substr($best_puzzle, 0, $prefix_length)) {
                            $lost = 1;
                            last;
                        }
                    }
                }
                last if $lost;
            }

            next if $lost || length($candidate) != 81;
            next if defined($best_puzzle) && $candidate ge $best_puzzle;

            for my $source_digit (1 .. 9) {
                $digit_map[$source_digit] ||= $next_digit++;
            }

            $best_puzzle = $candidate;
            $best_row_spec = $row_spec;
            $best_col_spec = $col_spec;
            $best_digits = [ @digit_map[1 .. 9] ];
        }
    }

    my $spatial = Sudoku::Symmetry->new(
        bands => $best_row_spec->{major},
        rows  => $best_row_spec->{locals},
        stacks => $best_col_spec->{major},
        cols   => $best_col_spec->{locals},
    );
    my $digit = Sudoku::Symmetry->new(digits => $best_digits);
    my $combined = $spatial->compose($digit);

    return Sudoku::Canonical::Result->new(
        puzzle    => $best_puzzle,
        transform => $combined,
        stage     => 'canonical',
    );
}

sub _normalized_row {
    my ($row, $target_to_source) = @_;

    my @digit_map = (0) x 10;
    my $next_digit = 1;
    my $normalized = q{};

    for my $source_col (@$target_to_source) {
        my $digit = substr($row, $source_col, 1);
        if ($digit ne '0') {
            $digit_map[$digit] ||= $next_digit++;
            $digit = $digit_map[$digit];
        }
        $normalized .= $digit;
    }

    return $normalized;
}

my %SPATIAL_SPECS;
sub _spatial_specs {
    my ($kind) = @_;
    return @{ $SPATIAL_SPECS{$kind} } if $SPATIAL_SPECS{$kind};

    my @specs;
    for my $major (_permutations([ 0 .. 2 ])) {
        for my $local0 (_permutations([ 0 .. 2 ])) {
            for my $local1 (_permutations([ 0 .. 2 ])) {
                for my $local2 (_permutations([ 0 .. 2 ])) {
                    my @locals = ($local0, $local1, $local2);
                    my @source_to_target;
                    for my $source (0 .. 8) {
                        my $source_major = int($source / 3);
                        my $source_local = $source % 3;
                        $source_to_target[$source] =
                            $major->[$source_major] * 3
                            + $locals[$source_major][$source_local];
                    }
                    my @target_to_source;
                    for my $source (0 .. 8) {
                        $target_to_source[$source_to_target[$source]] = $source;
                    }
                    push @specs, {
                        major => [ @$major ],
                        locals => [ map { [ @$_ ] } @locals ],
                        target_to_source => \@target_to_source,
                    };
                }
            }
        }
    }
    $SPATIAL_SPECS{$kind} = \@specs;
    return @specs;
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
