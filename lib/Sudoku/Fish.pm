package Sudoku::Fish;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(find_fish_patterns cell_label);

sub cell_label {
    my ($cell) = @_;

    return sprintf 'R%dC%d', $cell->row + 1, $cell->column + 1;
}

sub find_fish_patterns {
    my ( $grid, $size ) = @_;

    die "fish size must be at least 2\n" unless defined $size && $size >= 2;

    my @patterns;

    for my $value (1 .. 9) {
        push @patterns, _find_orientation($grid, $size, $value, 'row');
        push @patterns, _find_orientation($grid, $size, $value, 'column');
    }

    return @patterns;
}

sub _find_orientation {
    my ( $grid, $size, $value, $orientation ) = @_;

    my @eligible;

    for my $base_index (0 .. 8) {
        my @cover_indices;

        for my $cover_index (0 .. 8) {
            my $cell = $orientation eq 'row'
                ? $grid->cell_from_row_column($base_index, $cover_index)
                : $grid->cell_from_row_column($cover_index, $base_index);

            next if $cell->value;
            push @cover_indices, $cover_index
                if $cell->possibilities->[$value];
        }

        next if @cover_indices < 2;
        next if @cover_indices > $size;

        push @eligible, {
            base_index    => $base_index,
            cover_indices => \@cover_indices,
        };
    }

    my @patterns;

    for my $combination (_combinations(\@eligible, $size)) {
        my %cover;
        $cover{$_} = 1
            for map { @{ $_->{cover_indices} } } @{$combination};

        my @cover_indices = sort { $a <=> $b } keys %cover;
        next unless @cover_indices == $size;

        my @base_indices = map { $_->{base_index} } @{$combination};
        my %base = map { ($_ => 1) } @base_indices;
        my @pattern_cells;
        my @targets;

        for my $base_index (@base_indices) {
            for my $cover_index (@cover_indices) {
                my $cell = $orientation eq 'row'
                    ? $grid->cell_from_row_column($base_index, $cover_index)
                    : $grid->cell_from_row_column($cover_index, $base_index);

                push @pattern_cells, $cell
                    if !$cell->value && $cell->possibilities->[$value];
            }
        }

        for my $cover_index (@cover_indices) {
            for my $other_index (0 .. 8) {
                next if $base{$other_index};

                my $cell = $orientation eq 'row'
                    ? $grid->cell_from_row_column($other_index, $cover_index)
                    : $grid->cell_from_row_column($cover_index, $other_index);

                next if $cell->value;
                next unless $cell->possibilities->[$value];

                push @targets, $cell;
            }
        }

        next unless @targets;

        push @patterns, {
            orientation   => $orientation,
            value         => $value,
            base_indices  => \@base_indices,
            cover_indices => \@cover_indices,
            pattern_cells => \@pattern_cells,
            targets       => \@targets,
        };
    }

    return @patterns;
}

sub _combinations {
    my ( $items, $size, $start, $prefix ) = @_;

    $start  //= 0;
    $prefix //= [];

    return [ @{$prefix} ] if @{$prefix} == $size;

    my @combinations;
    my $needed = $size - @{$prefix};

    for my $index ($start .. @{$items} - $needed) {
        push @combinations, _combinations(
            $items,
            $size,
            $index + 1,
            [ @{$prefix}, $items->[$index] ],
        );
    }

    return @combinations;
}

1;
