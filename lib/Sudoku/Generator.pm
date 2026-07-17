package Sudoku::Generator;

use strict;
use warnings;

use Scalar::Util qw(blessed);

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
