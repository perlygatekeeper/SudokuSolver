package Sudoku::Corpus::Query;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        records => [ @{ $args{records} // [] } ],
    }, $class;
}

sub records {
    my ($self) = @_;
    return [ @{ $self->{records} } ];
}

sub count {
    my ($self) = @_;
    return scalar @{ $self->{records} };
}

sub first {
    my ($self) = @_;
    return $self->{records}[0];
}

sub ids {
    my ($self) = @_;
    my @ids = map { $_->{identity}{canonical_id} } @{ $self->{records} };
    return \@ids;
}

sub puzzles {
    my ($self) = @_;
    my @puzzles = map { $_->{identity}{canonical_puzzle} } @{ $self->{records} };
    return \@puzzles;
}

sub sort_by {
    my ($self, $field, %args) = @_;
    die "sort_by requires a field name\n" unless defined $field;

    my $direction = $args{direction} // $args{order} // 'asc';
    die "sort direction must be 'asc' or 'desc'\n"
        unless $direction =~ /\A(?:asc|desc)\z/;

    my @records = sort {
        _compare_values(_field_value($a, $field), _field_value($b, $field))
            || _compare_values($a->{identity}{canonical_id}, $b->{identity}{canonical_id})
    } @{ $self->{records} };

    @records = reverse @records if $direction eq 'desc';

    return __PACKAGE__->new(records => \@records);
}

sub limit {
    my ($self, $count) = @_;
    die "limit requires a non-negative integer\n"
        unless defined $count && !ref($count) && $count =~ /\A\d+\z/;

    my @records = @{ $self->{records} };
    splice @records, $count if @records > $count;
    return __PACKAGE__->new(records => \@records);
}

sub random {
    my ($self, %args) = @_;

    my $seed = $args{seed};
    die "random requires an integer seed\n"
        unless defined $seed && !ref($seed) && $seed =~ /\A-?\d+\z/;

    my @records = @{ $self->{records} };
    my $rng = Sudoku::Corpus::Query::_PRNG->new($seed);

    for (my $index = $#records; $index > 0; $index--) {
        my $swap = $rng->integer($index + 1);
        @records[$index, $swap] = @records[$swap, $index];
    }

    my $query = __PACKAGE__->new(records => \@records);
    return exists $args{limit} ? $query->limit($args{limit}) : $query;
}

sub _field_value {
    my ($record, $field) = @_;

    my %aliases = (
        id                 => 'canonical_id',
        canonical_id       => 'canonical_id',
        fingerprint        => 'fingerprint',
        puzzle             => 'canonical_puzzle',
        canonical_puzzle   => 'canonical_puzzle',
        clue_count         => 'clue_count',
        difficulty         => 'difficulty_label',
        difficulty_label   => 'difficulty_label',
        label              => 'difficulty_label',
        score              => 'difficulty_score',
        difficulty_score   => 'difficulty_score',
        highest_strategy   => 'highest_strategy',
        strategy           => 'highest_strategy',
        symmetry_count     => 'symmetry_count',
    );

    die "Unknown corpus sort field '$field'\n" unless exists $aliases{$field};
    my $resolved = $aliases{$field};

    return $record->{identity}{canonical_id} if $resolved eq 'canonical_id';
    return $record->{identity}{fingerprint} if $resolved eq 'fingerprint';
    return $record->{identity}{canonical_puzzle} if $resolved eq 'canonical_puzzle';
    return $record->{clue_count} if $resolved eq 'clue_count';
    return $record->{difficulty}{label} if $resolved eq 'difficulty_label';
    return $record->{difficulty}{score} if $resolved eq 'difficulty_score';
    return $record->{difficulty}{highest_strategy} if $resolved eq 'highest_strategy';
    return scalar @{ $record->{pattern_symmetries} } if $resolved eq 'symmetry_count';

    die "Unknown corpus sort field '$field'\n";
}

sub _compare_values {
    my ($left, $right) = @_;

    return 0 if !defined($left) && !defined($right);
    return -1 if !defined $left;
    return 1 if !defined $right;

    if ($left =~ /\A-?\d+(?:\.\d+)?\z/ && $right =~ /\A-?\d+(?:\.\d+)?\z/) {
        return $left <=> $right;
    }

    return $left cmp $right;
}

package Sudoku::Corpus::Query::_PRNG;

use strict;
use warnings;

sub new {
    my ($class, $seed) = @_;
    return bless { state => _normalize_seed($seed) }, $class;
}

sub integer {
    my ($self, $limit) = @_;
    die "integer limit must be positive\n" unless $limit > 0;
    $self->{state} = (1103515245 * $self->{state} + 12345) % 2147483648;
    return $self->{state} % $limit;
}

sub _normalize_seed {
    my ($seed) = @_;
    my $state = $seed % 2147483648;
    $state += 2147483648 if $state < 0;
    return $state;
}

1;
