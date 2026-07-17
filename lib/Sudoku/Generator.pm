package Sudoku::Generator;

use strict;
use warnings;

use Scalar::Util qw(blessed);

use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Corpus;
use Sudoku::Corpus::Query;
use Sudoku::GeneratedPuzzle;
use Sudoku::Symmetry;

sub new {
    my ($class, %args) = @_;

    my $corpus = $args{corpus};
    if (!defined $corpus) {
        $corpus = Sudoku::Corpus->new(
            exists $args{corpus_file} ? (file => $args{corpus_file}) : (),
        );
    }

    die "corpus must be a Sudoku::Corpus object\n"
        unless blessed($corpus) && $corpus->isa('Sudoku::Corpus');

    return bless { corpus => $corpus }, $class;
}

sub corpus {
    my ($self) = @_;
    return $self->{corpus};
}

sub symmetry_randomized {
    my ($self, %args) = @_;

    my $corpus_seed = _required_integer_seed(\%args, 'corpus_seed');
    my $symmetry_seed = _required_integer_seed(\%args, 'symmetry_seed');
    my $source = $self->_selection_source(%args);
    my $canonical_record = $source->random(
        seed  => $corpus_seed,
        limit => 1,
    )->first;

    die "corpus seed selected no canonical record\n"
        unless defined $canonical_record;

    my $transform = Sudoku::Symmetry->random(seed => $symmetry_seed);
    my $puzzle = $transform->apply_puzzle(
        $canonical_record->{identity}{canonical_puzzle},
    );
    my $solution = $transform->apply_puzzle($canonical_record->{solution});

    _verify_solution_preserves_puzzle($puzzle, $solution);

    return Sudoku::GeneratedPuzzle->new(
        canonical_record => $canonical_record,
        corpus_seed      => $corpus_seed,
        symmetry_seed    => $symmetry_seed,
        transform        => $transform,
        puzzle           => $puzzle,
        solution         => $solution,
    );
}

sub controlled_reveals {
    my ($self, %args) = @_;

    my $target_clue_count = _required_clue_count(\%args);
    my $reveal_seed = _required_integer_seed(\%args, 'reveal_seed');

    my $generated = $self->symmetry_randomized(%args);
    my $base_puzzle = $generated->puzzle;
    my $solution = $generated->solution;

    my $current_clues = clue_count($base_puzzle);
    die "clue_count cannot be less than the current clue count ($current_clues)\n"
        if $target_clue_count < $current_clues;

    my $needed = $target_clue_count - $current_clues;
    my @empty_cells = grep { substr($base_puzzle, $_, 1) eq '0' } 0 .. 80;
    die "not enough unrevealed cells to reach clue_count $target_clue_count\n"
        if $needed > @empty_cells;

    my @shuffled = _shuffled_indices($reveal_seed, @empty_cells);
    my @revealed_indices = $needed ? @shuffled[0 .. $needed - 1] : ();
    my $puzzle = _reveal_cells($base_puzzle, $solution, @revealed_indices);

    _verify_solution_preserves_puzzle($puzzle, $solution);

    return Sudoku::GeneratedPuzzle->new(
        canonical_record  => $generated->canonical_record,
        corpus_seed       => $generated->corpus_seed,
        symmetry_seed     => $generated->symmetry_seed,
        transform         => $generated->transform,
        base_puzzle       => $base_puzzle,
        puzzle            => $puzzle,
        solution          => $solution,
        reveal_seed       => $reveal_seed,
        reveal_cells      => [ map { _cell_label($_) } @revealed_indices ],
        target_clue_count => $target_clue_count,
    );
}

sub _selection_source {
    my ($self, %args) = @_;

    if (exists $args{query}) {
        die "query must be a Sudoku::Corpus::Query object\n"
            unless blessed($args{query})
                && $args{query}->isa('Sudoku::Corpus::Query');
        return $args{query};
    }

    if (exists $args{criteria}) {
        die "criteria must be a hash reference\n"
            unless ref($args{criteria}) eq 'HASH';
        return $self->corpus->select(%{ $args{criteria} });
    }

    return Sudoku::Corpus::Query->new(records => $self->corpus->records);
}

sub _required_integer_seed {
    my ($args, $name) = @_;
    die "$name is required\n" unless exists $args->{$name};
    die "$name must be an integer seed\n"
        unless defined $args->{$name}
            && !ref($args->{$name})
            && $args->{$name} =~ /\A-?\d+\z/;
    return 0 + $args->{$name};
}

sub _required_clue_count {
    my ($args) = @_;

    die "clue_count is required\n" unless exists $args->{clue_count};
    die "clue_count must be an integer from 0 through 81\n"
        unless defined $args->{clue_count}
            && !ref($args->{clue_count})
            && $args->{clue_count} =~ /\A\d+\z/
            && $args->{clue_count} <= 81;

    return 0 + $args->{clue_count};
}

sub _shuffled_indices {
    my ($seed, @indices) = @_;

    my $rng = Sudoku::Generator::_PRNG->new($seed);
    for (my $index = $#indices; $index > 0; $index--) {
        my $swap = $rng->integer($index + 1);
        @indices[$index, $swap] = @indices[$swap, $index];
    }

    return @indices;
}

sub _reveal_cells {
    my ($puzzle, $solution, @indices) = @_;

    my @cells = split //, $puzzle;
    for my $index (@indices) {
        die "reveal cell index must be between 0 and 80\n"
            unless defined $index && $index =~ /\A\d+\z/ && $index <= 80;
        die "reveal cell " . _cell_label($index) . " is already a clue\n"
            unless $cells[$index] eq '0';

        $cells[$index] = substr($solution, $index, 1);
    }

    return join q{}, @cells;
}

sub _cell_label {
    my ($index) = @_;
    return sprintf 'R%dC%d', int($index / 9) + 1, ($index % 9) + 1;
}

sub _verify_solution_preserves_puzzle {
    my ($puzzle, $solution) = @_;

    die "generated puzzle must contain exactly 81 normalized cells\n"
        unless defined($puzzle) && $puzzle =~ /\A[0-9]{81}\z/;
    die "generated solution must contain exactly 81 solved cells\n"
        unless defined($solution) && $solution =~ /\A[1-9]{81}\z/;

    for my $index (0 .. 80) {
        my $clue = substr($puzzle, $index, 1);
        next if $clue eq '0';
        die "generated solution does not preserve puzzle clue at cell "
            . ($index + 1) . "\n"
            unless substr($solution, $index, 1) eq $clue;
    }

    return 1;
}

1;

package Sudoku::Generator::_PRNG;

use strict;
use warnings;

sub new {
    my ($class, $seed) = @_;
    return bless { state => _normalize_seed($seed) }, $class;
}

sub integer {
    my ($self, $limit) = @_;
    die "random integer limit must be positive\n" unless $limit > 0;
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
