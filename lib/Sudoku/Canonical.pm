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

    # Stage 1: determine the globally smallest possible first row.  For each
    # source row, retain only column transforms capable of producing it.
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

    # Stage 2: among candidates tied through the first row, determine the
    # globally smallest possible first band (the first 27 characters).  A
    # candidate that loses anywhere in this prefix cannot be the full-grid
    # minimum, so only tied row/column pairs continue to Stage 3.
    my $best_first_band;
    my %best_first_band_pairs;

    # Only 18 distinct leading-band arrangements exist: choose one of the
    # three source bands, then choose one of its six row orders.  The complete
    # 1,296 row-family specifications repeat each leading arrangement 72
    # times while arranging the remaining two bands, so evaluating the unique
    # prefixes avoids that redundant work without changing the search space.
    for my $leading_rows (_leading_band_specs()) {
        my $first_source_row = $leading_rows->[0];
        my $eligible_columns = $first_row_columns{$first_source_row} || next;
        my @rows = map { $source_rows[$_] } @$leading_rows;

        for my $col_index (@$eligible_columns) {
            my $first_band = _normalized_prefix(
                \@rows,
                $col_specs[$col_index]{target_to_source},
                3,
            );
            my $pair_key = join(',', @$leading_rows) . ":$col_index";

            if (!defined($best_first_band) || $first_band lt $best_first_band) {
                $best_first_band = $first_band;
                %best_first_band_pairs = ($pair_key => 1);
            }
            elsif ($first_band eq $best_first_band) {
                $best_first_band_pairs{$pair_key} = 1;
            }
        }
    }

    # Stage 3: among candidates tied through the first band, determine the
    # globally smallest possible first two bands (the first 54 characters).
    # Only 216 distinct two-band arrangements exist: choose and order the
    # first source band, then choose and order a different second source band.
    # Complete row specifications repeat each such prefix six times while
    # arranging the final band, so evaluate each distinct prefix only once.
    my $best_first_two_bands;
    my %best_first_two_band_pairs;

    for my $leading_rows (_leading_two_band_specs()) {
        my @first_band_rows = @$leading_rows[0 .. 2];
        my $first_band_key = join(',', @first_band_rows);
        my @rows = map { $source_rows[$_] } @$leading_rows;

        for my $col_index (0 .. $#col_specs) {
            next unless $best_first_band_pairs{"$first_band_key:$col_index"};

            my $first_two_bands = _normalized_prefix(
                \@rows,
                $col_specs[$col_index]{target_to_source},
                6,
            );
            my $pair_key = join(',', @$leading_rows) . ":$col_index";

            if (!defined($best_first_two_bands)
                || $first_two_bands lt $best_first_two_bands) {
                $best_first_two_bands = $first_two_bands;
                %best_first_two_band_pairs = ($pair_key => 1);
            }
            elsif ($first_two_bands eq $best_first_two_bands) {
                $best_first_two_band_pairs{$pair_key} = 1;
            }
        }
    }

    # Stage 4: construct complete candidates only for row/column pairs tied
    # through the globally minimal first 54 characters. Prefix comparison
    # against the current best still stops losing candidates immediately.
    my $best_puzzle;
    my ($best_row_spec, $best_col_spec, $best_digits);

    for my $row_spec (@row_specs) {
        my @leading_rows = @{ $row_spec->{target_to_source} }[0 .. 5];
        my $leading_key = join(',', @leading_rows);
        my @rows = map { $source_rows[$_] } @{ $row_spec->{target_to_source} };

        for my $col_index (0 .. $#col_specs) {
            next unless $best_first_two_band_pairs{"$leading_key:$col_index"};
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

sub _leading_band_specs {
    my @specs;

    for my $source_band (0 .. 2) {
        for my $row_order (_permutations([ 0 .. 2 ])) {
            push @specs, [ map { $source_band * 3 + $_ } @$row_order ];
        }
    }

    return @specs;
}

sub _leading_two_band_specs {
    my @specs;

    for my $first_band (0 .. 2) {
        for my $first_order (_permutations([ 0 .. 2 ])) {
            my @first_rows = map { $first_band * 3 + $_ } @$first_order;

            for my $second_band (grep { $_ != $first_band } 0 .. 2) {
                for my $second_order (_permutations([ 0 .. 2 ])) {
                    my @second_rows =
                        map { $second_band * 3 + $_ } @$second_order;
                    push @specs, [ @first_rows, @second_rows ];
                }
            }
        }
    }

    return @specs;
}

sub _normalized_prefix {
    my ($rows, $target_to_source, $row_count) = @_;

    my @digit_map = (0) x 10;
    my $next_digit = 1;
    my $normalized = q{};

    for my $target_row (0 .. $row_count - 1) {
        my $row = $rows->[$target_row];
        for my $source_col (@$target_to_source) {
            my $digit = substr($row, $source_col, 1);
            if ($digit ne '0') {
                $digit_map[$digit] ||= $next_digit++;
                $digit = $digit_map[$digit];
            }
            $normalized .= $digit;
        }
    }

    return $normalized;
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
