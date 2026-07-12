package Sudoku::Strategy::UniqueRectangleType1;

use strict;
use warnings;

use parent 'Sudoku::Strategy::Base';

use Sudoku::Deduction;
use Sudoku::Uniqueness qw(
candidate_values
candidate_key
cell_label
rectangle_cells
rectangle_uses_two_boxes
);

sub name {
return 'Unique Rectangle Type 1';
}

sub apply {
my ($self, $grid) = @_;

my @deductions;
my %seen;

for my $row_a (0 .. 7) {
    for my $row_b ($row_a + 1 .. 8) {
        for my $column_a (0 .. 7) {
            for my $column_b ($column_a + 1 .. 8) {
                my @cells = rectangle_cells(
                    $grid,
                    $row_a,
                    $row_b,
                    $column_a,
                    $column_b,
                );

                next if grep { $_->value } @cells;
                next unless rectangle_uses_two_boxes(@cells);

                my %pair_cells;

                for my $cell (@cells) {
                    next unless $cell->possibilities->[0] == 2;

                    push @{
                        $pair_cells{ candidate_key($cell) }
                    }, $cell;
                }

                for my $pair_key (keys %pair_cells) {
                    my @floor = @{ $pair_cells{$pair_key} };

                    next unless @floor == 3;

                    my ($roof) = grep {
                        my $candidate = $_;

                        !grep {
                            $_ == $candidate
                        } @floor;
                    } @cells;

                    next unless $roof;

                    my @pair = split /,/, $pair_key;

                    my %roof_values = map {
                        ($_ => 1)
                    } candidate_values($roof);

                    next if grep {
                        !$roof_values{$_}
                    } @pair;

                    next unless $roof->possibilities->[0] > 2;

                    my $pattern = join q{, },
                        map { cell_label($_) } @cells;

                    my @floor_labels =
                        map { cell_label($_) } @floor;

                    my $roof_label = cell_label($roof);

                    for my $value (@pair) {
                        next unless
                            $roof->possibilities->[$value];

                        my $key = join q{:},
                            $roof->row,
                            $roof->column,
                            $value;

                        next if $seen{$key}++;

                        push @deductions,
                            Sudoku::Deduction->new(
                                strategy => $self->name,
                                action   => 'remove_candidate',
                                cell     => $roof,
                                value    => 0 + $value,
                                cells    => \@cells,

                                reason => sprintf(
                                    '%s, %s, and %s contain only {%s}. '
                                    . 'If %s also contained %d, the four '
                                    . 'cells could form a deadly rectangle '
                                    . 'with two solutions. Because the '
                                    . 'puzzle is assumed to have a unique '
                                    . 'solution, %s cannot contain %d.',
                                    $floor_labels[0],
                                    $floor_labels[1],
                                    $floor_labels[2],
                                    $pair_key,
                                    $roof_label,
                                    $value,
                                    $roof_label,
                                    $value,
                                ),

                                explanation => sprintf(
                                    'Remove candidate %d from %s. '
                                    . 'Rectangle cells: %s.',
                                    $value,
                                    $roof_label,
                                    $pattern,
                                ),
                            );
                    }
                }
            }
        }
    }
}

return @deductions;

}

1;

