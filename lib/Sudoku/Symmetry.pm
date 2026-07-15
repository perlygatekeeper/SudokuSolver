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

sub from_shorthand {
    my ($class, $text) = @_;

    die "symmetry shorthand is required\n"
        unless defined $text && !ref($text) && length $text;

    my $digit = qr/[1-9]{9}/;
    my $small = qr/[0-2]{3}/;
    my $locals = qr/[0-2]{3}\|[0-2]{3}\|[0-2]{3}/;

    die "invalid symmetry shorthand\n"
        unless $text =~ /\AD=($digit);B=($small);R=($locals);S=($small);C=($locals)\z/;

    my ($digits, $bands, $rows, $stacks, $cols) = ($1, $2, $3, $4, $5);

    return $class->new(
        digits => [ map { 0 + $_ } split //, $digits ],
        bands  => [ map { 0 + $_ } split //, $bands ],
        rows   => [ map { [ map { 0 + $_ } split // ] } split /\|/, $rows ],
        stacks => [ map { 0 + $_ } split //, $stacks ],
        cols   => [ map { [ map { 0 + $_ } split // ] } split /\|/, $cols ],
    );
}

sub random {
    my ($class, %args) = @_;

    die "random symmetry generation requires an integer seed\n"
        unless defined $args{seed}
            && !ref($args{seed})
            && $args{seed} =~ /\A-?\d+\z/;

    my $rng = Sudoku::Symmetry::_PRNG->new($args{seed});

    return $class->new(
        digits => _shuffled($rng, [ 1 .. 9 ]),
        bands  => _shuffled($rng, [ 0 .. 2 ]),
        rows   => [ map { _shuffled($rng, [ 0 .. 2 ]) } 0 .. 2 ],
        stacks => _shuffled($rng, [ 0 .. 2 ]),
        cols   => [ map { _shuffled($rng, [ 0 .. 2 ]) } 0 .. 2 ],
    );
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


sub inverse {
    my ($self) = @_;

    my @inverse_digits = (0) x 9;
    for my $source_digit (1 .. 9) {
        my $target_digit = $self->{digits}[ $source_digit - 1 ];
        $inverse_digits[ $target_digit - 1 ] = $source_digit;
    }

    my $inverse_rows = _invert_absolute_permutation($self->_absolute_rows);
    my $inverse_cols = _invert_absolute_permutation($self->_absolute_cols);

    return __PACKAGE__->_from_absolute_permutations(
        digits => \@inverse_digits,
        rows   => $inverse_rows,
        cols   => $inverse_cols,
    );
}

sub compose {
    my ($self, $next) = @_;

    die "compose requires another Sudoku::Symmetry transform\n"
        unless ref($next) && $next->isa(__PACKAGE__);

    my @digits = map {
        $next->{digits}[ $self->{digits}[$_ - 1] - 1 ]
    } 1 .. 9;

    my $rows = _compose_absolute_permutations(
        $self->_absolute_rows,
        $next->_absolute_rows,
    );
    my $cols = _compose_absolute_permutations(
        $self->_absolute_cols,
        $next->_absolute_cols,
    );

    return __PACKAGE__->_from_absolute_permutations(
        digits => \@digits,
        rows   => $rows,
        cols   => $cols,
    );
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) && $other->isa(__PACKAGE__);
    return $self->serialize eq $other->serialize;
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


sub _absolute_rows {
    my ($self) = @_;
    my @rows;

    for my $source_row (0 .. 8) {
        my $source_band = int($source_row / 3);
        my $row_in_band = $source_row % 3;
        push @rows,
            $self->{bands}[$source_band] * 3
            + $self->{rows}[$source_band][$row_in_band];
    }

    return \@rows;
}

sub _absolute_cols {
    my ($self) = @_;
    my @cols;

    for my $source_col (0 .. 8) {
        my $source_stack = int($source_col / 3);
        my $col_in_stack = $source_col % 3;
        push @cols,
            $self->{stacks}[$source_stack] * 3
            + $self->{cols}[$source_stack][$col_in_stack];
    }

    return \@cols;
}

sub _from_absolute_permutations {
    my ($class, %args) = @_;

    my (@bands, @rows, @stacks, @cols);

    for my $source_band (0 .. 2) {
        my @targets = map { $args{rows}[ $source_band * 3 + $_ ] } 0 .. 2;
        my $target_band = int($targets[0] / 3);

        die "absolute row permutation does not preserve band structure\n"
            if grep { int($_ / 3) != $target_band } @targets;

        push @bands, $target_band;
        push @rows, [ map { $_ % 3 } @targets ];
    }

    for my $source_stack (0 .. 2) {
        my @targets = map { $args{cols}[ $source_stack * 3 + $_ ] } 0 .. 2;
        my $target_stack = int($targets[0] / 3);

        die "absolute column permutation does not preserve stack structure\n"
            if grep { int($_ / 3) != $target_stack } @targets;

        push @stacks, $target_stack;
        push @cols, [ map { $_ % 3 } @targets ];
    }

    return $class->new(
        digits => $args{digits},
        bands  => \@bands,
        rows   => \@rows,
        stacks => \@stacks,
        cols   => \@cols,
    );
}

sub _invert_absolute_permutation {
    my ($permutation) = @_;
    my @inverse = (0) x @$permutation;

    for my $source (0 .. $#$permutation) {
        $inverse[ $permutation->[$source] ] = $source;
    }

    return \@inverse;
}

sub _compose_absolute_permutations {
    my ($first, $second) = @_;
    return [ map { $second->[ $first->[$_] ] } 0 .. $#$first ];
}

sub _shuffled {
    my ($rng, $values) = @_;
    my @copy = @$values;

    for (my $index = $#copy; $index > 0; $index--) {
        my $swap = $rng->integer($index + 1);
        @copy[$index, $swap] = @copy[$swap, $index];
    }

    return \@copy;
}

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


package Sudoku::Symmetry::_PRNG;

use strict;
use warnings;

sub new {
    my ($class, $seed) = @_;

    # Normalize to an unsigned 32-bit state. Xorshift32 cannot use zero.
    my $state = $seed & 0xffffffff;
    $state = 0x6d2b79f5 if $state == 0;

    return bless { state => $state }, $class;
}

sub integer {
    my ($self, $limit) = @_;
    die "random integer limit must be positive\n" unless $limit > 0;
    return $self->_next_u32 % $limit;
}

sub _next_u32 {
    my ($self) = @_;
    my $x = $self->{state};

    $x ^= ($x << 13) & 0xffffffff;
    $x ^= ($x >> 17);
    $x ^= ($x << 5) & 0xffffffff;
    $x &= 0xffffffff;

    $self->{state} = $x;
    return $x;
}

package Sudoku::Symmetry;

1;
