#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Strategy::Skyscraper;

sub remove_candidate_except {
    my ( $grid, $orientation, $base_index, $value, @keep ) = @_;

    my %keep = map { ($_ => 1) } @keep;

    for my $cover_index (0 .. 8) {
        next if $keep{$cover_index};

        my $cell = $orientation eq 'row'
            ? $grid->cell_from_row_column($base_index, $cover_index)
            : $grid->cell_from_row_column($cover_index, $base_index);

        $cell->remove_possibility($value);
    }
}

sub keep_candidate_only_at {
    my ( $grid, $value, @coordinates ) = @_;

    my %keep = map { ( join(q{:}, @{$_}) => 1 ) } @coordinates;

    for my $row (0 .. 8) {
        for my $column (0 .. 8) {
            next if $keep{ join(q{:}, $row, $column) };
            $grid->cell_from_row_column($row, $column)
                ->remove_possibility($value);
        }
    }
}

sub deduction_for {
    my ( $deductions, $cell, $value ) = @_;

    return scalar grep {
           $_->cell == $cell
        && $_->value == $value
    } @{$deductions};
}

my $strategy = Sudoku::Strategy::Skyscraper->new;
is($strategy->name, 'Skyscraper', 'strategy reports canonical name');

my $row_grid = Grid->new;
$row_grid->load_from_string('.' x 81);

# Candidate 5 has row strong links R1C1-R1C5 and R4C1-R4C6.
# The floor cells share column 1.  Therefore at least one roof,
# R1C5 or R4C6, is 5.  R2C6 and R3C6 see both roofs: they see
# R1C5 through the top-middle box and R4C6 through column 6.
remove_candidate_except($row_grid, 'row', 0, 5, 0, 4);
remove_candidate_except($row_grid, 'row', 3, 5, 0, 5);

# R5C5 and R6C5 also see both roofs.  Remove candidate 5 there so
# this fixture has exactly the two intended eliminations.
$row_grid->cell_from_row_column(4, 4)->remove_possibility(5);
$row_grid->cell_from_row_column(5, 4)->remove_possibility(5);

my $row_target_one = $row_grid->cell_from_row_column(1, 5);
my $row_target_two = $row_grid->cell_from_row_column(2, 5);
my @row_deductions = $strategy->apply($row_grid);

is(scalar @row_deductions, 2, 'row-based Skyscraper finds two eliminations');
is(deduction_for(\@row_deductions, $row_target_one, 5), 1,
    'row-based Skyscraper removes candidate from first common peer');
is(deduction_for(\@row_deductions, $row_target_two, 5), 1,
    'row-based Skyscraper removes candidate from second common peer');

my ($row_deduction) = grep { $_->cell == $row_target_one } @row_deductions;
isa_ok($row_deduction, 'Sudoku::Deduction');
is($row_deduction->strategy, 'Skyscraper', 'deduction records strategy');
is($row_deduction->action, 'remove_candidate', 'deduction removes a candidate');
like($row_deduction->reason, qr/row-based Skyscraper/, 'reason identifies orientation');
like($row_deduction->reason, qr/R1C5 or R4C6/, 'reason identifies both roofs');
like($row_deduction->reason, qr/R2C6 cannot contain 5/, 'reason identifies target');

is($row_grid->apply_deductions(@row_deductions), 2,
    'row-based deductions apply');
ok(!$row_target_one->possibilities->[5], 'first row target loses candidate');
ok(!$row_target_two->possibilities->[5], 'second row target loses candidate');

my $column_grid = Grid->new;
$column_grid->load_from_string('.' x 81);

# Transposed pattern: C1 and C4 are the base columns, row 1 is shared,
# and the roofs are R5C1 and R6C4.  Retain candidate 7 only in the
# four pattern cells and the two intended common peers.  This avoids
# incidental Skyscrapers in the otherwise empty candidate grid.
keep_candidate_only_at(
    $column_grid,
    7,
    [ 0, 0 ],    # R1C1 floor
    [ 4, 0 ],    # R5C1 roof
    [ 0, 3 ],    # R1C4 floor
    [ 5, 3 ],    # R6C4 roof
    [ 5, 1 ],    # R6C2 target
    [ 5, 2 ],    # R6C3 target
);

my $column_target_one = $column_grid->cell_from_row_column(5, 1);
my $column_target_two = $column_grid->cell_from_row_column(5, 2);
my @column_deductions = $strategy->apply($column_grid);

is(scalar @column_deductions, 2, 'column-based Skyscraper finds two eliminations');
is(deduction_for(\@column_deductions, $column_target_one, 7), 1,
    'column-based Skyscraper removes candidate from first common peer');
is(deduction_for(\@column_deductions, $column_target_two, 7), 1,
    'column-based Skyscraper removes candidate from second common peer');
like($column_deductions[0]->reason, qr/column-based Skyscraper/,
    'column-based reason identifies orientation');

my $negative_grid = Grid->new;
$negative_grid->load_from_string('.' x 81);

# These row strong links share no cover column, so they are not a Skyscraper.
remove_candidate_except($negative_grid, 'row', 0, 6, 0, 4);
remove_candidate_except($negative_grid, 'row', 3, 6, 2, 8);

my @negative = $strategy->apply($negative_grid);
is(scalar @negative, 0, 'strong links without a shared floor do not form a Skyscraper');

my $xwing_grid = Grid->new;
$xwing_grid->load_from_string('.' x 81);

# Sharing both cover columns is an X-Wing, not a Skyscraper.
remove_candidate_except($xwing_grid, 'row', 0, 8, 1, 6);
remove_candidate_except($xwing_grid, 'row', 5, 8, 1, 6);

my @xwing = $strategy->apply($xwing_grid);
is(scalar @xwing, 0, 'two shared endpoints are not misidentified as a Skyscraper');

done_testing();
