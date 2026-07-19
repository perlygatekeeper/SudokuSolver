#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Grid;
use Solver;
use Sudoku::CLI::Suggestion qw(suggest_value);
use Sudoku::Config;
use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Corpus;
use Sudoku::GeneratedPuzzle;
use Sudoku::Generator;
use Sudoku::Render::Text;
use Sudoku::Strategy;

my $seed = 1;
my $corpus_seed;
my $symmetry_seed;
my $reveal_seed;
my $clue_count = 30;
my $difficulty;
my $min_score;
my $max_score;
my $score;
my $highest_strategy;
my $strategy_ceiling;
my $max_attempts = 100;
my $corpus_file;
my $format = 'summary';
my $character_set = 'UNICODE_LIGHT';
my $output_file;
my $debug;
my $help;

my %config = Sudoku::Config->new->defaults_for(
    'generate-puzzle' => qw(
        seed corpus-seed symmetry-seed reveal-seed clues clue-count
        difficulty min-score max-score score highest-strategy strategy-ceiling
        max-attempts corpus-file format character-set
    ),
);

$seed = $config{seed} if exists $config{seed};
$corpus_seed = $config{'corpus-seed'} if exists $config{'corpus-seed'};
$symmetry_seed = $config{'symmetry-seed'} if exists $config{'symmetry-seed'};
$reveal_seed = $config{'reveal-seed'} if exists $config{'reveal-seed'};
$clue_count = $config{clues} if exists $config{clues};
$clue_count = $config{'clue-count'} if exists $config{'clue-count'};
$difficulty = $config{difficulty} if exists $config{difficulty};
$min_score = $config{'min-score'} if exists $config{'min-score'};
$max_score = $config{'max-score'} if exists $config{'max-score'};
$score = $config{score} if exists $config{score};
$highest_strategy = $config{'highest-strategy'} if exists $config{'highest-strategy'};
$strategy_ceiling = $config{'strategy-ceiling'} if exists $config{'strategy-ceiling'};
$max_attempts = $config{'max-attempts'} if exists $config{'max-attempts'};
$corpus_file = $config{'corpus-file'} if exists $config{'corpus-file'};
$format = $config{format} if exists $config{format};
$character_set = $config{'character-set'} if exists $config{'character-set'};

GetOptions(
    'seed=i'             => \$seed,
    'corpus-seed=i'      => \$corpus_seed,
    'symmetry-seed=i'    => \$symmetry_seed,
    'reveal-seed=i'      => \$reveal_seed,
    'clues|clue-count=i' => \$clue_count,
    'difficulty=s'       => \$difficulty,
    'min-score=i'        => \$min_score,
    'max-score=i'        => \$max_score,
    'score=i'            => \$score,
    'highest-strategy=s' => \$highest_strategy,
    'strategy-ceiling=s' => \$strategy_ceiling,
    'max-attempts=i'     => \$max_attempts,
    'corpus-file=s'      => \$corpus_file,
    'format=s'           => \$format,
    'character-set=s'    => \$character_set,
    'output-file=s'      => \$output_file,
    'debug'              => \$debug,
    'help|h'             => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

$corpus_seed   //= $seed;
$symmetry_seed //= $seed + 1;
$reveal_seed   //= $seed + 2;

_validate_integer(seed => $seed);
_validate_integer(corpus_seed => $corpus_seed);
_validate_integer(symmetry_seed => $symmetry_seed);
_validate_integer(reveal_seed => $reveal_seed);
_validate_positive_integer(max_attempts => $max_attempts);

die "--clues must be an integer from 0 through 81\n"
    unless defined($clue_count) && $clue_count =~ /\A\d+\z/ && $clue_count <= 81;

$format = lc($format // 'summary');
$character_set = uc($character_set // 'UNICODE_LIGHT');
$character_set =~ tr/-/_/;

my $renderer = Sudoku::Render::Text->new(
    character_set => $character_set,
    color         => 'never',
);

my @document_formats = qw(puzzle solution summary json);
my @grid_formats = $renderer->available_grid_formats;
my @formats = (@document_formats, @grid_formats);
_validate_choice(
    label   => 'format',
    value   => $format,
    choices => \@formats,
);

my @character_sets = Sudoku::Render::Text->available_character_sets;
_validate_choice(
    label   => 'character set',
    value   => $character_set,
    choices => \@character_sets,
);

my %criteria;
$criteria{difficulty} = $difficulty if defined $difficulty;
$criteria{highest_strategy} = $highest_strategy if defined $highest_strategy;

if (defined $score || defined $min_score || defined $max_score) {
    my %score_spec;
    $score_spec{value} = $score if defined $score;
    $score_spec{min} = $min_score if defined $min_score;
    $score_spec{max} = $max_score if defined $max_score;
    $criteria{score} = \%score_spec;
}

my $corpus = Sudoku::Corpus->new(
    defined($corpus_file) ? (file => $corpus_file) : (),
);
my $source = %criteria
    ? $corpus->select(%criteria)
    : $corpus->select(score => { min => 2 });
die "No corpus records matched the requested generation criteria\n"
    unless $source->count;

my $generator = Sudoku::Generator->new(corpus => $corpus);
my ($generated, $metadata);

for my $attempt (1 .. $max_attempts) {
    my $base = $generator->symmetry_randomized(
        query         => $source,
        corpus_seed   => $corpus_seed + $attempt - 1,
        symmetry_seed => $symmetry_seed + $attempt - 1,
    );

    my $result = _generate_from_solve_path(
        generated_base => $base,
        target_clues   => $clue_count,
        reveal_seed    => $reveal_seed + $attempt - 1,
    );

    my $accepted = $result->{status} eq 'candidate'
        && _difficulty_matches($result->{difficulty});

    _debug_attempt(
        attempt   => $attempt,
        base      => $base,
        result    => $result,
        accepted  => $accepted,
    ) if $debug;

    next unless $accepted;

    $generated = Sudoku::GeneratedPuzzle->new(
        canonical_record     => $base->canonical_record,
        corpus_seed          => $base->corpus_seed,
        symmetry_seed        => $base->symmetry_seed,
        transform            => $base->transform,
        base_puzzle          => $base->base_puzzle,
        puzzle               => $result->{puzzle},
        solution             => $base->solution,
        reveal_seed          => $reveal_seed + $attempt - 1,
        reveal_cells         => $result->{reveal_cells},
        target_clue_count    => $clue_count,
        difficulty           => $result->{difficulty}->as_hash,
        generation_attempts  => $attempt,
    );
    $metadata = $result;
    last;
}

die "No solve-path generated puzzle matched the requested constraints "
    . "within $max_attempts attempt(s)\n"
    unless $generated;

if (defined $output_file) {
    my $mode = $format =~ /\A(?:png|pdf)\z/ ? '>:raw' : '>:encoding(UTF-8)';
    open STDOUT, $mode, $output_file
        or die "Cannot open output file '$output_file': $!\n";
}

if ($format eq 'puzzle') {
    say $generated->puzzle;
}
elsif ($format eq 'solution') {
    say $generated->solution;
}
elsif ($format eq 'summary') {
    print _summary($generated, $metadata);
}
elsif ($format eq 'json') {
    print $generated->as_json;
}
else {
    my $grid = Grid->new;
    $grid->load_from_string($generated->puzzle);
    binmode STDOUT, ':raw' if $format =~ /\A(?:png|pdf)\z/;
    binmode STDOUT, ':encoding(UTF-8)'
        if $format !~ /\A(?:png|pdf)\z/;
    print $renderer->render_grid($grid, format => $format);
}

exit 0;

sub _generate_from_solve_path {
    my (%args) = @_;

    my $base = $args{generated_base};
    my $target_clues = $args{target_clues};
    my $base_puzzle = $base->puzzle;
    my $current_clues = clue_count($base_puzzle);
    my $protected_strategy = $base->canonical_record->{difficulty}{highest_strategy};

    die "Source corpus record has no highest_strategy to protect\n"
        unless defined $protected_strategy && length $protected_strategy;
    die "clue_count cannot be less than the current clue count ($current_clues)\n"
        if $target_clues < $current_clues;

    if ($target_clues == $current_clues) {
        my $difficulty = _rate_puzzle($base_puzzle);
        return {
            status             => 'candidate',
            puzzle             => $base_puzzle,
            reveal_cells       => [],
            protected_strategy => $protected_strategy,
            solve_steps        => 0,
            placement_reveals  => 0,
            difficulty         => $difficulty,
            reason             => 'target clues already present',
        };
    }

    my $grid = Grid->new;
    $grid->load_from_string($base_puzzle);
    my $solver = Solver->new(output_mode => 'quiet');
    my @cells = split //, $base_puzzle;
    my @reveal_cells;
    my $solve_steps = 0;
    my $placement_reveals = 0;

    while (clue_count(join q{}, @cells) < $target_clues) {
        my $deduction = $solver->hint($grid);
        return {
            status             => 'rejected',
            puzzle             => join(q{}, @cells),
            reveal_cells       => \@reveal_cells,
            protected_strategy => $protected_strategy,
            solve_steps        => $solve_steps,
            placement_reveals  => $placement_reveals,
            reason             => 'solver stalled before target clues',
        } unless $deduction;

        if (_strategy_reaches_protected($deduction->strategy, $protected_strategy)) {
            return {
                status             => 'rejected',
                puzzle             => join(q{}, @cells),
                reveal_cells       => \@reveal_cells,
                protected_strategy => $protected_strategy,
                solve_steps        => $solve_steps,
                placement_reveals  => $placement_reveals,
                reached_strategy   => $deduction->strategy,
                reason             => 'protected strategy reached before target clues',
            };
        }

        my $progress = $solver->apply_deduction($grid, $deduction);
        next unless $progress;
        $solve_steps++;

        next unless $deduction->action eq 'set_value';

        my $index = _deduction_index($deduction);
        next unless defined $index;
        next unless $cells[$index] eq '0';

        $cells[$index] = $deduction->value;
        push @reveal_cells, _cell_label($index);
        $placement_reveals++;
    }

    my $puzzle = join q{}, @cells;
    my $difficulty = _rate_puzzle($puzzle);
    return {
        status             => 'candidate',
        puzzle             => $puzzle,
        reveal_cells       => \@reveal_cells,
        protected_strategy => $protected_strategy,
        solve_steps        => $solve_steps,
        placement_reveals  => $placement_reveals,
        difficulty         => $difficulty,
        reason             => 'target clues reached before protected strategy',
    };
}

sub _difficulty_matches {
    my ($difficulty_rating) = @_;

    return 0 unless $difficulty_rating;
    return 0 if defined($difficulty) && $difficulty_rating->label ne $difficulty;
    return 0 if defined($highest_strategy)
        && ($difficulty_rating->highest_strategy // q{}) ne $highest_strategy;
    return 0 if defined($score) && $difficulty_rating->score != $score;
    return 0 if defined($min_score) && $difficulty_rating->score < $min_score;
    return 0 if defined($max_score) && $difficulty_rating->score > $max_score;
    return 0 if defined($strategy_ceiling)
        && !_strategy_at_or_below_ceiling($difficulty_rating, $strategy_ceiling);

    return 1;
}

sub _strategy_at_or_below_ceiling {
    my ($difficulty_rating, $ceiling) = @_;

    if ($ceiling =~ /\A\d+\z/) {
        return $difficulty_rating->score <= $ceiling;
    }

    my $strategy = $difficulty_rating->highest_strategy;
    return 1 unless defined $strategy;
    return _strategy_rank($strategy) <= _strategy_rank($ceiling);
}

sub _strategy_reaches_protected {
    my ($strategy, $protected) = @_;
    return _strategy_rank($strategy) >= _strategy_rank($protected);
}

sub _strategy_rank {
    my ($strategy) = @_;

    state %rank = do {
        my $index = 0;
        map { $_ => ++$index } Sudoku::Strategy->ordered_strategy_names;
    };

    die "Unknown strategy '$strategy'\n"
        unless defined($strategy) && exists $rank{$strategy};

    return $rank{$strategy};
}

sub _rate_puzzle {
    my ($puzzle) = @_;

    my $solver = Solver->new(output_mode => 'quiet');
    my $grid = $solver->run(
        puzzle_string => $puzzle,
        output_mode   => 'quiet',
    );

    die "generated puzzle did not solve cleanly\n"
        unless $grid->solved == 81 && !$solver->has_contradiction;

    return $solver->difficulty;
}

sub _summary {
    my ($generated, $metadata) = @_;

    my @lines = (
        'Generated Puzzle',
        '================',
        q{},
        'Generation mode:     solve-path',
        'Puzzle:              ' . $generated->puzzle,
        'Solution:            ' . $generated->solution,
        'Canonical ID:        ' . $generated->canonical_id,
        'Fingerprint:         ' . $generated->fingerprint,
        'Clues:               ' . $generated->clue_count,
        'Corpus seed:         ' . $generated->corpus_seed,
        'Symmetry seed:       ' . $generated->symmetry_seed,
        'Reveal seed:         ' . ($generated->reveal_seed // q{}),
        'Transform:           ' . $generated->transform_shorthand,
        'Reveal cells:        ' . join(',', @{ $generated->reveal_cells }),
        'Protected strategy:  ' . ($metadata->{protected_strategy} // q{}),
        'Solve-path steps:    ' . ($metadata->{solve_steps} // 0),
        'Placement reveals:   ' . ($metadata->{placement_reveals} // 0),
    );

    if (defined $generated->difficulty_label) {
        push @lines,
            'Difficulty:          ' . $generated->difficulty_label,
            'Difficulty score:    ' . $generated->difficulty_score,
            'Highest strategy:    ' . ($generated->highest_strategy // q{}),
            'Rating version:      ' . $generated->difficulty_rating_version,
            'Generation attempts: ' . $generated->generation_attempts;
    }

    push @lines, q{};
    return join("\n", @lines);
}

sub _debug_attempt {
    my (%event) = @_;

    my $base = $event{base};
    my $result = $event{result};
    my $record = $base->canonical_record;
    my $initial = $record->{difficulty} // {};
    my $corpus_number = _corpus_number($record);
    my $final_difficulty = $result->{difficulty}
        ? $result->{difficulty}->label
        : 'not rated';
    my $decision = $event{accepted} ? 'accept' : 'reject';

    printf STDERR
        "Attempt %d: Starting with Corpus #%s (%s), initial difficulty: %s, protected strategy: %s, %s after %d solve-path step(s), final difficulty: %s, %s.\n",
        $event{attempt},
        $corpus_number,
        $base->canonical_id,
        $initial->{label} // 'Unknown',
        $result->{protected_strategy} // 'Unknown',
        $result->{reason},
        $result->{solve_steps} // 0,
        $final_difficulty,
        $decision;

    return;
}

sub _corpus_number {
    my ($record) = @_;

    my $canonical_id = $record->{identity}{canonical_id} // q{};
    return 0 + $1 if $canonical_id =~ /-(\d+)\z/;
    return $record->{provenance}{source_ordinal}
        if defined $record->{provenance}{source_ordinal};
    return '?';
}

sub _deduction_index {
    my ($deduction) = @_;

    if ($deduction->has_cell) {
        return $deduction->cell->row * 9 + $deduction->cell->column;
    }

    return unless $deduction->has_row && $deduction->has_column;
    return $deduction->row * 9 + $deduction->column;
}

sub _cell_label {
    my ($index) = @_;
    return sprintf 'R%dC%d', int($index / 9) + 1, ($index % 9) + 1;
}

sub _validate_integer {
    my (%args) = @_;
    my ($name) = keys %args;
    my $value = $args{$name};
    die "--$name must be an integer seed\n"
        unless defined($value) && $value =~ /\A-?\d+\z/;
}

sub _validate_positive_integer {
    my (%args) = @_;
    my ($name) = keys %args;
    my $value = $args{$name};
    die "--$name must be a positive integer\n"
        unless defined($value) && $value =~ /\A[1-9]\d*\z/;
}

sub _validate_choice {
    my (%args) = @_;
    my %known = map { $_ => 1 } @{ $args{choices} };
    return if $known{ $args{value} };

    my $available = join ', ', @{ $args{choices} };
    my $message = "Unknown $args{label} '$args{value}'; available values: $available\n";
    my $suggestion = suggest_value(
        input   => $args{value},
        choices => $args{choices},
    );
    $message .= "Did you mean '$suggestion'?\n" if defined $suggestion;
    die $message;
}

__END__

=head1 NAME

generate-puzzle.pl - generate Sudoku puzzles by preserving the solve path

=head1 SYNOPSIS

  bin/generate-puzzle.pl --difficulty Medium --clues 30
  bin/generate-puzzle.pl --difficulty Medium --clues 30 --format worksheet
  bin/generate-puzzle.pl --difficulty Medium --clues 30 --debug
  bin/generate-puzzle.pl --score 3 --clues 30 --output-file generated.json --format json

=head1 DESCRIPTION

Generates puzzles from the canonical corpus by following the source puzzle's
logical solve path. The selected source puzzle is symmetry-randomized, then
the solver walks deductions in order. Deductions that place values are promoted
to givens until the requested clue count is reached. If the source puzzle's
highest required strategy appears before enough givens are revealed, the
attempt is rejected so the interesting strategy is not consumed.

Use C<bin/generate-puzzle-random.pl> for the older random-reveal generator.

=head1 OPTIONS

=over 4

=item B<--seed N>

Base integer seed. Defaults to 1. Unless overridden, C<--corpus-seed> uses N,
C<--symmetry-seed> uses N+1, and C<--reveal-seed> uses N+2.

=item B<--corpus-seed N>, B<--symmetry-seed N>, B<--reveal-seed N>

Explicit integer seeds for corpus selection, symmetry transform, and reveal
provenance.

=item B<--clues N>

Final clue count. Defaults to 30.

=item B<--difficulty LABEL>

Start from corpus records with this difficulty label and accept only generated
puzzles that retain this label.

=item B<--score N>, B<--min-score N>, B<--max-score N>

Restrict source records and final accepted puzzles by difficulty score.

=item B<--highest-strategy NAME>

Restrict source records and final accepted puzzles to this highest required
strategy.

=item B<--strategy-ceiling NAME_OR_SCORE>

Accept only generated puzzles at or below this strategy difficulty.

=item B<--max-attempts N>

Maximum deterministic candidates to try. Defaults to 100.

=item B<--corpus-file FILE>

Use a specific master corpus JSONL or JSONL.gz file.

=item B<--format FORMAT>

Output format. Document formats are C<summary>, C<puzzle>, C<solution>, and
C<json>. Any registered grid format may also be used, including C<worksheet>.

=item B<--character-set NAME>

Character set for grid output formats. Defaults to C<UNICODE_LIGHT>.

=item B<--output-file FILE>

Write output to a file instead of standard output.

=item B<--debug>

Print each attempt to standard error.

=item B<-h, --help>

Show this help.

=back

=head1 CONFIGURATION

Personal defaults may be stored in C<~/.sudoku_solver>:

  [generate-puzzle]
  clues = 30
  difficulty = Medium
  format = summary

Command-line options override config-file defaults. Set
C<SUDOKU_SOLVER_CONFIG=/path/to/file> to use a different config file, or set it
to an empty value to disable personal defaults for one command.
