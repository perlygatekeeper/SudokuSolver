#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Grid;
use Sudoku::CLI::Suggestion qw(suggest_value);
use Sudoku::Generator;
use Sudoku::Render::Text;

my $seed = 1;
my $corpus_seed;
my $symmetry_seed;
my $reveal_seed;
my $clue_count = 17;
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

my %generator_args = (
    corpus_seed   => $corpus_seed,
    symmetry_seed => $symmetry_seed,
    reveal_seed   => $reveal_seed,
    clue_count    => $clue_count,
);

$generator_args{max_attempts} = $max_attempts;
$generator_args{difficulty} = $difficulty if defined $difficulty;
$generator_args{highest_strategy} = $highest_strategy if defined $highest_strategy;
$generator_args{strategy_ceiling} = $strategy_ceiling if defined $strategy_ceiling;

if (defined $score || defined $min_score || defined $max_score) {
    my %score_spec;
    $score_spec{value} = $score if defined $score;
    $score_spec{min} = $min_score if defined $min_score;
    $score_spec{max} = $max_score if defined $max_score;
    $generator_args{score} = \%score_spec;
}

$generator_args{attempt_callback} = \&_debug_attempt if $debug;

my $uses_difficulty_targeting =
       defined($difficulty)
    || defined($highest_strategy)
    || defined($strategy_ceiling)
    || defined($score)
    || defined($min_score)
    || defined($max_score);

my $generator = Sudoku::Generator->new(
    defined($corpus_file) ? (corpus_file => $corpus_file) : (),
);

my $generated = $uses_difficulty_targeting
    ? $generator->difficulty_targeted(%generator_args)
    : $generator->controlled_reveals(%generator_args);

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
    print _summary($generated);
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

sub _summary {
    my ($generated) = @_;

    my @lines = (
        'Generated Puzzle',
        '================',
        q{},
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

    my $generated = $event{generated};
    my $difficulty = $event{difficulty};
    my $record = $generated->canonical_record;
    my $initial = $record->{difficulty} // {};
    my $corpus_number = _corpus_number($record);
    my $target_clues = $generated->target_clue_count;
    my $decision = $event{accepted} ? 'accept' : 'reject';

    printf STDERR
        "Attempt %d: Starting with Corpus #%s (%s), initial difficulty: %s, after revealing up to %d clues, final difficulty: %s, %s.\n",
        $event{attempt},
        $corpus_number,
        $generated->canonical_id,
        $initial->{label} // 'Unknown',
        $target_clues,
        $difficulty->label,
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

generate-puzzle.pl - generate reproducible Sudoku puzzles from the canonical corpus

=head1 SYNOPSIS

  bin/generate-puzzle.pl --seed 123 --clues 30
  bin/generate-puzzle.pl --seed 123 --clues 30 --difficulty Medium --format worksheet
  bin/generate-puzzle.pl --seed 123 --clues 30 --difficulty Medium --debug
  bin/generate-puzzle.pl --corpus-seed 10 --symmetry-seed 20 --reveal-seed 30 --format json
  bin/generate-puzzle.pl --seed 123 --difficulty Easy --max-score 3 --output-file generated.json --format json

=head1 DESCRIPTION

Generates a reproducible Sudoku puzzle from the bundled canonical corpus.
The generator selects a canonical record, applies a seeded Sudoku-preserving
symmetry transform, and then reveals solution values until the requested clue
count is reached.

When difficulty options are supplied, the command tries deterministic
successive seeds until a generated puzzle matches the requested difficulty
constraints or C<--max-attempts> is reached.

=head1 OPTIONS

=over 4

=item B<--seed N>

Base integer seed. Defaults to 1. Unless overridden, C<--corpus-seed> uses
N, C<--symmetry-seed> uses N+1, and C<--reveal-seed> uses N+2.

=item B<--corpus-seed N>, B<--symmetry-seed N>, B<--reveal-seed N>

Explicit integer seeds for corpus selection, symmetry transform, and clue
reveals.

=item B<--clues N>

Final clue count. Defaults to 17.

=item B<--difficulty LABEL>

Accept only generated puzzles with this difficulty label.

=item B<--score N>, B<--min-score N>, B<--max-score N>

Accept only generated puzzles matching the requested difficulty score.

=item B<--highest-strategy NAME>

Accept only generated puzzles whose highest required strategy matches NAME.

=item B<--strategy-ceiling NAME_OR_SCORE>

Accept only generated puzzles at or below this strategy difficulty.

=item B<--max-attempts N>

Maximum deterministic candidates to try when difficulty targeting is active.
Defaults to 100.

=item B<--format FORMAT>

Output format. Document formats are C<summary>, C<puzzle>, C<solution>, and
C<json>. Any registered grid format may also be used, including C<worksheet>,
C<pretty>, C<candidates>, C<markdown>, C<html>, C<svg>, C<png>, and C<pdf>.

=item B<--character-set NAME>

Grid character set for text grid formats. Defaults to C<UNICODE_LIGHT>.

=item B<--corpus-file FILE>

Read a specific master corpus JSONL or JSONL.gz file.

=item B<--output-file FILE>

Write output to FILE.

=item B<--debug>

When difficulty targeting is active, print each generation attempt to standard
error with the selected corpus record, starting difficulty, final generated
difficulty, and accept/reject decision.

=item B<-h, --help>

Show this help.

=back
