package Sudoku::Generator;

use strict;
use warnings;

use JSON::PP;
use Scalar::Util qw(blessed);

use Solver;
use Sudoku::CoordinateEncoding qw(clue_count encode_puzzle);
use Sudoku::Corpus;
use Sudoku::Corpus::Query;
use Sudoku::Difficulty;
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
        canonical_record  => $canonical_record,
        corpus_seed       => $corpus_seed,
        symmetry_seed     => $symmetry_seed,
        transform         => $transform,
        puzzle            => $puzzle,
        solution          => $solution,
        generation_date   => $args{generation_date},
        generator_version => $args{generator_version},
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
        generation_date   => $args{generation_date},
        generator_version => $args{generator_version},
    );
}

sub difficulty_targeted {
    my ($self, %args) = @_;

    my $max_attempts = _optional_positive_integer(\%args, 'max_attempts', 100);
    my $base_corpus_seed = _required_integer_seed(\%args, 'corpus_seed');
    my $base_symmetry_seed = _required_integer_seed(\%args, 'symmetry_seed');
    my $base_reveal_seed = _required_integer_seed(\%args, 'reveal_seed');
    my $source = $self->_difficulty_target_selection_source(%args);

    for my $attempt (0 .. $max_attempts - 1) {
        my %candidate_args = %args;
        $candidate_args{corpus_seed} = $base_corpus_seed + $attempt;
        $candidate_args{symmetry_seed} = $base_symmetry_seed + $attempt;
        $candidate_args{reveal_seed} = $base_reveal_seed + $attempt;
        $candidate_args{query} = $source;
        delete $candidate_args{criteria};

        my $generated = $self->controlled_reveals(%candidate_args);
        my $difficulty = $self->_rate_generated_puzzle($generated);
        my $accepted = _difficulty_matches($difficulty, %args);

        _notify_attempt(
            \%args,
            attempt    => $attempt + 1,
            generated  => $generated,
            difficulty => $difficulty,
            accepted   => $accepted,
        );

        next unless $accepted;

        return _copy_generated(
            $generated,
            difficulty          => $difficulty->as_hash,
            generation_attempts => $attempt + 1,
        );
    }

    die "No generated puzzle matched the requested difficulty constraints "
        . "within $max_attempts attempt(s)\n";
}

sub replay {
    my ($self, %args) = @_;

    my $data = _replay_data(%args);
    my $provenance = $data->{provenance};
    die "generated puzzle provenance is required\n"
        unless ref($provenance) eq 'HASH';

    my $canonical_id = $provenance->{canonical_id};
    die "generated puzzle provenance requires canonical_id\n"
        unless defined $canonical_id;

    my $canonical_record = $self->corpus->find_by_id($canonical_id);
    die "canonical ID '$canonical_id' was not found in the corpus\n"
        unless defined $canonical_record;

    if (defined $provenance->{fingerprint}) {
        die "stored fingerprint does not match corpus record\n"
            unless $provenance->{fingerprint}
                eq $canonical_record->{identity}{fingerprint};
    }

    my $transform = Sudoku::Symmetry->from_shorthand(
        $provenance->{symmetry_transform},
    );
    my $base_puzzle = $transform->apply_puzzle(
        $canonical_record->{identity}{canonical_puzzle},
    );
    my $solution = $transform->apply_puzzle($canonical_record->{solution});
    my $puzzle = _reveal_cells_by_label(
        $base_puzzle,
        $solution,
        @{ $provenance->{reveal_cells} // [] },
    );

    _verify_solution_preserves_puzzle($puzzle, $solution);

    die "replayed puzzle does not match stored puzzle\n"
        if defined($data->{puzzle}) && $puzzle ne $data->{puzzle};
    die "replayed solution does not match stored solution\n"
        if defined($data->{solution}) && $solution ne $data->{solution};
    die "replayed base puzzle does not match stored base puzzle\n"
        if defined($data->{base_puzzle}) && $base_puzzle ne $data->{base_puzzle};
    die "replayed clue count does not match stored final clue count\n"
        if defined($provenance->{final_clue_count})
            && clue_count($puzzle) != $provenance->{final_clue_count};
    die "replayed coordinate encoding does not match stored coordinate encoding\n"
        if defined($provenance->{coordinate_encoding})
            && encode_puzzle($puzzle) ne $provenance->{coordinate_encoding};

    if (($args{verify_difficulty} // 1) && ref($data->{difficulty}) eq 'HASH') {
        my $difficulty = $self->_rate_puzzle_string($puzzle);
        _verify_difficulty_metadata($data->{difficulty}, $difficulty);
    }

    return Sudoku::GeneratedPuzzle->new(
        canonical_record     => $canonical_record,
        corpus_seed          => $provenance->{corpus_seed},
        symmetry_seed        => $provenance->{symmetry_seed},
        transform            => $transform,
        base_puzzle          => $base_puzzle,
        puzzle               => $puzzle,
        solution             => $solution,
        reveal_seed          => $provenance->{reveal_seed},
        reveal_cells         => $provenance->{reveal_cells} // [],
        target_clue_count    => $provenance->{target_clue_count}
            // $provenance->{final_clue_count},
        difficulty           => $data->{difficulty},
        generation_attempts  => $provenance->{generation_attempts},
        generation_date      => $provenance->{generation_date},
        generator_version    => $provenance->{generator_version},
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

sub _difficulty_target_selection_source {
    my ($self, %args) = @_;

    my $source = $self->_selection_source(%args);
    my $minimum_score = _minimum_base_score_for_difficulty_target(%args);
    return $source unless defined $minimum_score;

    my @records = grep {
        defined $_->{difficulty}{score}
            && $_->{difficulty}{score} >= $minimum_score
    } @{ $source->records };

    die "No corpus records satisfy the base difficulty prefilter "
        . "(score >= $minimum_score)\n"
        unless @records;

    return Sudoku::Corpus::Query->new(records => \@records);
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

sub _optional_positive_integer {
    my ($args, $name, $default) = @_;
    return $default unless exists $args->{$name};
    die "$name must be a positive integer\n"
        unless defined $args->{$name}
            && !ref($args->{$name})
            && $args->{$name} =~ /\A[1-9]\d*\z/;
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

sub _reveal_cells_by_label {
    my ($puzzle, $solution, @labels) = @_;
    return _reveal_cells(
        $puzzle,
        $solution,
        map { _cell_index_from_label($_) } @labels,
    );
}

sub _cell_index_from_label {
    my ($label) = @_;
    die "reveal cell label must look like RrCc\n"
        unless defined $label && !ref($label) && $label =~ /\AR([1-9])C([1-9])\z/;
    return ($1 - 1) * 9 + ($2 - 1);
}

sub _cell_label {
    my ($index) = @_;
    return sprintf 'R%dC%d', int($index / 9) + 1, ($index % 9) + 1;
}

sub _rate_generated_puzzle {
    my ($self, $generated) = @_;
    return $self->_rate_puzzle_string($generated->puzzle);
}

sub _rate_puzzle_string {
    my ($self, $puzzle) = @_;

    my $solver = Solver->new(output_mode => 'quiet');
    my $grid = $solver->run(
        puzzle_string => $puzzle,
        output_mode   => 'quiet',
    );

    die "generated puzzle did not solve cleanly for difficulty rating\n"
        unless $grid->solved == 81 && !$solver->has_contradiction;

    return $solver->difficulty;
}

sub _difficulty_matches {
    my ($difficulty, %args) = @_;

    return 0 if exists $args{difficulty}
        && !_matches_scalar_spec($difficulty->label, $args{difficulty});
    return 0 if exists $args{difficulty_label}
        && !_matches_scalar_spec($difficulty->label, $args{difficulty_label});
    return 0 if exists $args{score}
        && !_matches_scalar_spec($difficulty->score, $args{score});
    return 0 if exists $args{difficulty_score}
        && !_matches_scalar_spec($difficulty->score, $args{difficulty_score});
    return 0 if exists $args{highest_strategy}
        && !_matches_scalar_spec(
            $difficulty->highest_strategy // q{},
            $args{highest_strategy},
        );

    if (exists $args{strategy_ceiling}) {
        my $ceiling = _strategy_ceiling_score($args{strategy_ceiling});
        return 0 if $difficulty->score > $ceiling;
    }

    return 1;
}

sub _notify_attempt {
    my ($args, %event) = @_;

    return unless exists $args->{attempt_callback};
    my $callback = $args->{attempt_callback};
    die "attempt_callback must be a code reference\n"
        unless ref($callback) eq 'CODE';

    $callback->(%event);
    return;
}

sub _minimum_base_score_for_difficulty_target {
    my (%args) = @_;

    my @floors;

    push @floors, _minimum_score_from_label_spec($args{difficulty})
        if exists $args{difficulty};
    push @floors, _minimum_score_from_label_spec($args{difficulty_label})
        if exists $args{difficulty_label};
    push @floors, _minimum_score_from_score_spec($args{score})
        if exists $args{score};
    push @floors, _minimum_score_from_score_spec($args{difficulty_score})
        if exists $args{difficulty_score};
    push @floors, _minimum_score_from_strategy_spec($args{highest_strategy})
        if exists $args{highest_strategy};

    @floors = grep { defined } @floors;
    return unless @floors;

    my $minimum = $floors[0];
    for my $floor (@floors[1 .. $#floors]) {
        $minimum = $floor if $floor > $minimum;
    }

    return $minimum;
}

sub _minimum_score_from_label_spec {
    my ($spec) = @_;

    return unless defined $spec;

    if (ref($spec) eq 'HASH') {
        return _minimum_score_from_label_spec($spec->{value})
            if exists $spec->{value};
        return _minimum_score_from_label_spec($spec->{eq})
            if exists $spec->{eq};
        return _minimum_defined(
            map { _minimum_score_from_label_spec($_) } @{ _as_array($spec->{in}) },
        ) if exists $spec->{in};
        return _minimum_defined(
            map { _minimum_score_from_label_spec($_) } @{ _as_array($spec->{any}) },
        ) if exists $spec->{any};

        return;
    }

    if (ref($spec) eq 'ARRAY') {
        return _minimum_defined(map { _minimum_score_from_label_spec($_) } @{$spec});
    }

    my $difficulty = Sudoku::Difficulty->new(
        label               => 'Unrated',
        score               => 0,
        statistics_snapshot => {},
    );
    return $difficulty->label_min_score($spec);
}

sub _minimum_score_from_score_spec {
    my ($spec) = @_;

    return unless defined $spec;

    if (ref($spec) eq 'HASH') {
        return _minimum_score_from_score_spec($spec->{value})
            if exists $spec->{value};
        return _minimum_score_from_score_spec($spec->{eq})
            if exists $spec->{eq};
        return _minimum_defined(
            map { _minimum_score_from_score_spec($_) } @{ _as_array($spec->{in}) },
        ) if exists $spec->{in};
        return _minimum_defined(
            map { _minimum_score_from_score_spec($_) } @{ _as_array($spec->{any}) },
        ) if exists $spec->{any};
        return $spec->{min} if exists $spec->{min} && _is_number($spec->{min});
        return $spec->{gte} if exists $spec->{gte} && _is_number($spec->{gte});
        return $spec->{gt} + 1 if exists $spec->{gt} && _is_number($spec->{gt});

        return;
    }

    if (ref($spec) eq 'ARRAY') {
        return _minimum_defined(map { _minimum_score_from_score_spec($_) } @{$spec});
    }

    return 0 + $spec if _is_number($spec);
    return;
}

sub _minimum_score_from_strategy_spec {
    my ($spec) = @_;

    return unless defined $spec;

    if (ref($spec) eq 'HASH') {
        return _minimum_score_from_strategy_spec($spec->{value})
            if exists $spec->{value};
        return _minimum_score_from_strategy_spec($spec->{eq})
            if exists $spec->{eq};
        return _minimum_defined(
            map { _minimum_score_from_strategy_spec($_) } @{ _as_array($spec->{in}) },
        ) if exists $spec->{in};
        return _minimum_defined(
            map { _minimum_score_from_strategy_spec($_) } @{ _as_array($spec->{any}) },
        ) if exists $spec->{any};

        return;
    }

    if (ref($spec) eq 'ARRAY') {
        return _minimum_defined(map { _minimum_score_from_strategy_spec($_) } @{$spec});
    }

    my $difficulty = Sudoku::Difficulty->new(
        label               => 'Unrated',
        score               => 0,
        statistics_snapshot => {},
    );
    my $score = $difficulty->strategy_score($spec);
    return $score || undef;
}

sub _minimum_defined {
    my @values = grep { defined } @_;
    return unless @values;

    my $minimum = $values[0];
    for my $value (@values[1 .. $#values]) {
        $minimum = $value if $value < $minimum;
    }

    return $minimum;
}

sub _matches_scalar_spec {
    my ($actual, $expected) = @_;

    if (ref($expected) eq 'HASH') {
        return 0 if exists $expected->{not}
            && _matches_scalar_spec($actual, $expected->{not});
        return 0 if exists $expected->{exclude}
            && _matches_scalar_spec($actual, $expected->{exclude});

        my $has_positive = 0;
        for my $key (qw(value eq in any min max gt gte lt lte)) {
            $has_positive ||= exists $expected->{$key};
        }
        return 1 unless $has_positive;

        my $ok = 1;
        $ok &&= _matches_scalar_spec($actual, $expected->{value})
            if exists $expected->{value};
        $ok &&= _matches_scalar_spec($actual, $expected->{eq})
            if exists $expected->{eq};
        $ok &&= _matches_any($actual, @{ _as_array($expected->{in}) })
            if exists $expected->{in};
        $ok &&= _matches_any($actual, @{ _as_array($expected->{any}) })
            if exists $expected->{any};

        $ok &&= _is_number($actual) && $actual >= $expected->{min}
            if exists $expected->{min};
        $ok &&= _is_number($actual) && $actual <= $expected->{max}
            if exists $expected->{max};
        $ok &&= _is_number($actual) && $actual >  $expected->{gt}
            if exists $expected->{gt};
        $ok &&= _is_number($actual) && $actual >= $expected->{gte}
            if exists $expected->{gte};
        $ok &&= _is_number($actual) && $actual <  $expected->{lt}
            if exists $expected->{lt};
        $ok &&= _is_number($actual) && $actual <= $expected->{lte}
            if exists $expected->{lte};

        return $ok ? 1 : 0;
    }

    if (ref($expected) eq 'ARRAY') {
        return _matches_any($actual, @{$expected});
    }

    return defined($actual) && defined($expected) && "$actual" eq "$expected";
}

sub _matches_any {
    my ($actual, @expected) = @_;
    for my $item (@expected) {
        return 1 if _matches_scalar_spec($actual, $item);
    }
    return 0;
}

sub _as_array {
    my ($value) = @_;
    return [] unless defined $value;
    return $value if ref($value) eq 'ARRAY';
    return [$value];
}

sub _is_number {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A-?\d+(?:\.\d+)?\z/;
}

sub _strategy_ceiling_score {
    my ($ceiling) = @_;
    die "strategy_ceiling must be a score or strategy name\n"
        unless defined $ceiling && !ref($ceiling);
    return 0 + $ceiling if $ceiling =~ /\A\d+\z/;

    my $difficulty = Sudoku::Difficulty->new(
        label               => 'Unrated',
        score               => 0,
        statistics_snapshot => {},
    );
    my $score = $difficulty->strategy_score($ceiling);
    die "Unknown strategy ceiling '$ceiling'\n" unless $score;
    return $score;
}

sub _copy_generated {
    my ($generated, %extra) = @_;

    return Sudoku::GeneratedPuzzle->new(
        canonical_record     => $generated->canonical_record,
        corpus_seed          => $generated->corpus_seed,
        symmetry_seed        => $generated->symmetry_seed,
        transform            => $generated->transform,
        base_puzzle          => $generated->base_puzzle,
        puzzle               => $generated->puzzle,
        solution             => $generated->solution,
        reveal_seed          => $generated->reveal_seed,
        reveal_cells         => $generated->reveal_cells,
        target_clue_count    => $generated->target_clue_count,
        difficulty           => $extra{difficulty} // $generated->difficulty,
        generation_attempts  => $extra{generation_attempts}
            // $generated->generation_attempts,
        generation_date      => $extra{generation_date}
            // $generated->generation_date,
        generator_version    => $extra{generator_version}
            // $generated->generator_version,
    );
}

sub _replay_data {
    my (%args) = @_;

    if (exists $args{file}) {
        open my $in, '<:encoding(UTF-8)', $args{file}
            or die "Cannot open '$args{file}': $!\n";
        local $/;
        my $text = <$in>;
        close $in
            or die "Cannot close '$args{file}': $!\n";
        return JSON::PP->new->decode($text);
    }

    if (exists $args{data}) {
        die "replay data must be a hash reference\n"
            unless ref($args{data}) eq 'HASH';
        return $args{data};
    }

    die "replay requires file or data\n";
}

sub _verify_difficulty_metadata {
    my ($stored, $actual) = @_;

    for my $field (qw(rating_version label score highest_strategy)) {
        my $left = defined $stored->{$field} ? "$stored->{$field}" : q{};
        my $right = defined $actual->$field ? $actual->$field : q{};
        die "stored difficulty $field does not match replayed difficulty\n"
            unless $left eq "$right";
    }

    return 1;
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
