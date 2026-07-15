package Sudoku::Symmetry;

use strict;
use warnings;

use Sudoku::CoordinateEncoding qw(validate_puzzle_string);

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        digits => $args{digits} // [ 1 .. 9 ],
        bands  => $args{bands}  // [ 0 .. 2 ],
        rows   => $args{rows}   // [ map { [ 0 .. 2 ] } 0 .. 2 ],
        stacks => $args{stacks} // [ 0 .. 2 ],
        cols   => $args{cols}   // [ map { [ 0 .. 2 ] } 0 .. 2 ],
    }, $class;

    $self->_validate;
    return $self;
}

sub identity {
    my ($class) = @_;
    return $class->new;
}

sub apply_puzzle {
    my ($self, $puzzle) = @_;
    $puzzle = validate_puzzle_string($puzzle);

    my @output = ('0') x 81;

    for my $source_index (0 .. 80) {
        my $digit = substr($puzzle, $source_index, 1);
        next if $digit eq '0';

        my $source_row = int($source_index / 9);
        my $source_col = $source_index % 9;

        my $source_band  = int($source_row / 3);
        my $source_stack = int($source_col / 3);
        my $row_in_band  = $source_row % 3;
        my $col_in_stack = $source_col % 3;

        my $target_row =
            $self->{bands}[$source_band] * 3
            + $self->{rows}[$source_band][$row_in_band];

        my $target_col =
            $self->{stacks}[$source_stack] * 3
            + $self->{cols}[$source_stack][$col_in_stack];

        my $target_digit = $self->{digits}[ $digit - 1 ];
        $output[$target_row * 9 + $target_col] = $target_digit;
    }

    return join q{}, @output;
}

sub serialize {
    my ($self) = @_;

    return join ';',
        'D=' . join(q{}, @{ $self->{digits} }),
        'B=' . join(q{}, @{ $self->{bands} }),
        'R=' . join('|', map { join(q{}, @$_) } @{ $self->{rows} }),
        'S=' . join(q{}, @{ $self->{stacks} }),
        'C=' . join('|', map { join(q{}, @$_) } @{ $self->{cols} });
}

sub is_identity {
    my ($self) = @_;
    return $self->serialize eq __PACKAGE__->identity->serialize;
}

sub digits { return [ @{ $_[0]->{digits} } ] }
sub bands  { return [ @{ $_[0]->{bands}  } ] }
sub stacks { return [ @{ $_[0]->{stacks} } ] }
sub rows   { return [ map { [ @$_ ] } @{ $_[0]->{rows} } ] }
sub cols   { return [ map { [ @$_ ] } @{ $_[0]->{cols} } ] }

sub _validate {
    my ($self) = @_;

    _validate_permutation('digit permutation', $self->{digits}, [ 1 .. 9 ]);
    _validate_permutation('band permutation',  $self->{bands},  [ 0 .. 2 ]);
    _validate_permutation('stack permutation', $self->{stacks}, [ 0 .. 2 ]);

    _validate_local_permutations('row permutations', $self->{rows});
    _validate_local_permutations('column permutations', $self->{cols});

    return 1;
}

sub _validate_local_permutations {
    my ($name, $sets) = @_;

    die "$name must contain exactly three permutations\n"
        unless ref($sets) eq 'ARRAY' && @$sets == 3;

    for my $index (0 .. 2) {
        _validate_permutation(
            "$name entry " . ($index + 1),
            $sets->[$index],
            [ 0 .. 2 ],
        );
    }
}

sub _validate_permutation {
    my ($name, $values, $expected) = @_;

    die "$name must be an array reference\n"
        unless ref($values) eq 'ARRAY';

    die "$name must contain exactly " . scalar(@$expected) . " values\n"
        unless @$values == @$expected;

    my @actual = sort { $a <=> $b } @$values;
    my @wanted = sort { $a <=> $b } @$expected;

    for my $index (0 .. $#wanted) {
        die "$name is not a valid permutation\n"
            if !defined($actual[$index])
                || $actual[$index] !~ /\A\d+\z/
                || $actual[$index] != $wanted[$index];
    }

    return 1;
}

1;
