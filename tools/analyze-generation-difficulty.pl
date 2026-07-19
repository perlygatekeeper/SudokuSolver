#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Solver;
use Sudoku::Corpus;
use Sudoku::Corpus::Query;
use Sudoku::Generator;

my $samples = 100;
my $clues = 30;
my $base_difficulty;
my $base_score;
my $base_min_score;
my $base_max_score;
my $base_highest_strategy;
my $seed = 1;
my $corpus_file;
my $progress = 100;
my $help;

GetOptions(
    'samples=i'              => \$samples,
    'clues|clue-count=i'     => \$clues,
    'base-difficulty=s'      => \$base_difficulty,
    'base-score=i'           => \$base_score,
    'base-min-score=i'       => \$base_min_score,
    'base-max-score=i'       => \$base_max_score,
    'base-highest-strategy=s' => \$base_highest_strategy,
    'seed=i'                 => \$seed,
    'corpus-file=s'          => \$corpus_file,
    'progress=i'             => \$progress,
    'help|h'                 => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

_validate_positive_integer(samples => $samples);
_validate_integer(seed => $seed);
_validate_non_negative_integer(progress => $progress);
_validate_integer('base-score' => $base_score) if defined $base_score;
_validate_integer('base-min-score' => $base_min_score) if defined $base_min_score;
_validate_integer('base-max-score' => $base_max_score) if defined $base_max_score;
die "--clues must be an integer from 0 through 81\n"
    unless defined($clues) && $clues =~ /\A\d+\z/ && $clues <= 81;

my %criteria;
$criteria{difficulty} = $base_difficulty if defined $base_difficulty;
$criteria{highest_strategy} = $base_highest_strategy
    if defined $base_highest_strategy;

if (defined $base_score || defined $base_min_score || defined $base_max_score) {
    my %score_spec;
    $score_spec{value} = $base_score if defined $base_score;
    $score_spec{min} = $base_min_score if defined $base_min_score;
    $score_spec{max} = $base_max_score if defined $base_max_score;
    $criteria{score} = \%score_spec;
}

my $corpus = Sudoku::Corpus->new(
    defined($corpus_file) ? (file => $corpus_file) : (),
);
my $base_query = %criteria ? $corpus->select(%criteria)
                           : Sudoku::Corpus::Query->new(records => $corpus->records);
my $base_records = $base_query->records;
die "No corpus records matched the requested base criteria\n"
    unless @{$base_records};

my $generator = Sudoku::Generator->new(corpus => $corpus);
my $rng = _PRNG->new($seed);

my (%final_label, %final_score, %final_strategy, %transition);
my (%base_label, %base_score_seen, %base_strategy);
my ($completed, $failed) = (0, 0);
my $rating_version = q{};

for my $sample (1 .. $samples) {
    my $record = $base_records->[ $rng->integer(scalar @{$base_records}) ];
    my $base = $record->{difficulty} // {};

    $base_label{ $base->{label} // 'Unknown' }++;
    $base_score_seen{ $base->{score} // 'Unknown' }++;
    $base_strategy{ $base->{highest_strategy} // 'none' }++;

    my $generated = eval {
        $generator->controlled_reveals(
            query         => Sudoku::Corpus::Query->new(records => [$record]),
            corpus_seed   => $seed + $sample,
            symmetry_seed => $seed + 1_000_003 * $sample,
            reveal_seed   => $seed + 2_000_003 * $sample,
            clue_count    => $clues,
        );
    };

    if (!$generated) {
        warn "Sample $sample failed during generation: $@";
        $failed++;
        next;
    }

    my $difficulty = eval { _rate_puzzle($generated->puzzle) };
    if (!$difficulty) {
        warn "Sample $sample failed during rating: $@";
        $failed++;
        next;
    }

    $rating_version ||= $difficulty->rating_version;
    $completed++;

    my $final_label_name = $difficulty->label;
    my $final_score_value = $difficulty->score;
    my $final_strategy_name = $difficulty->highest_strategy // 'none';

    $final_label{$final_label_name}++;
    $final_score{$final_score_value}++;
    $final_strategy{$final_strategy_name}++;
    $transition{ ($base->{label} // 'Unknown') . "\t" . $final_label_name }++;

    if ($progress && $sample % $progress == 0) {
        printf STDERR "Processed %d / %d samples\n", $sample, $samples;
    }
}

_print_report(
    corpus              => $corpus,
    base_pool_count     => scalar @{$base_records},
    samples             => $samples,
    completed           => $completed,
    failed              => $failed,
    clues               => $clues,
    seed                => $seed,
    rating_version      => $rating_version || 'unknown',
    criteria            => \%criteria,
    base_label          => \%base_label,
    base_score          => \%base_score_seen,
    base_strategy       => \%base_strategy,
    final_label         => \%final_label,
    final_score         => \%final_score,
    final_strategy      => \%final_strategy,
    transition          => \%transition,
);

exit($failed ? 1 : 0);

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

sub _print_report {
    my (%args) = @_;

    say 'Generation Difficulty Analysis';
    say '==============================';
    say q{};
    say 'Corpus file:       ' . $args{corpus}->file;
    say 'Corpus cache:      ' . ($args{corpus}->using_cache ? 'yes' : 'no');
    say 'Base criteria:     ' . _criteria_summary($args{criteria});
    say 'Base pool:         ' . _comma($args{base_pool_count});
    say 'Target clues:      ' . $args{clues};
    say 'Samples requested: ' . _comma($args{samples});
    say 'Samples completed: ' . _comma($args{completed});
    say 'Samples failed:    ' . _comma($args{failed});
    say 'Seed:              ' . $args{seed};
    say 'Rating version:    ' . $args{rating_version};
    say 'Sampling:          with replacement';
    say q{};

    _print_count_table(
        title => 'Base Difficulty Labels Sampled',
        counts => $args{base_label},
        total => $args{samples},
        order => [ qw(Trivial Easy Medium Hard Expert Master Unrated Unknown) ],
    );
    _print_count_table(
        title => 'Final Difficulty Labels',
        counts => $args{final_label},
        total => $args{completed},
        order => [ qw(Trivial Easy Medium Hard Expert Master Unrated Unknown) ],
    );
    _print_count_table(
        title => 'Final Difficulty Scores',
        counts => $args{final_score},
        total => $args{completed},
        numeric => 1,
    );
    _print_count_table(
        title => 'Final Highest Required Strategy',
        counts => $args{final_strategy},
        total => $args{completed},
        by_count => 1,
    );

    _print_transition_table(
        counts => $args{transition},
        total  => $args{completed},
    );
}

sub _print_count_table {
    my (%args) = @_;

    say $args{title};
    say '-' x length($args{title});
    say '| Value | Count | Share |';
    say '| --- | ---: | ---: |';

    my @keys = _ordered_keys(%args);
    for my $key (@keys) {
        my $count = $args{counts}{$key} // 0;
        next unless $count;
        printf "| %s | %s | %s |\n",
            $key,
            _comma($count),
            _percent($count, $args{total});
    }
    say q{};
}

sub _print_transition_table {
    my (%args) = @_;

    say 'Base to Final Difficulty Labels';
    say '-------------------------------';
    say '| Base | Final | Count | Share |';
    say '| --- | --- | ---: | ---: |';

    for my $key (sort {
        my ($a_base, $a_final) = split /\t/, $a, 2;
        my ($b_base, $b_final) = split /\t/, $b, 2;
        _label_rank($a_base) <=> _label_rank($b_base)
            || _label_rank($a_final) <=> _label_rank($b_final)
            || $a cmp $b;
    } keys %{ $args{counts} }) {
        my ($base, $final) = split /\t/, $key, 2;
        my $count = $args{counts}{$key};
        printf "| %s | %s | %s | %s |\n",
            $base,
            $final,
            _comma($count),
            _percent($count, $args{total});
    }
    say q{};
}

sub _ordered_keys {
    my (%args) = @_;
    my $counts = $args{counts};

    if ($args{numeric}) {
        return sort { $a <=> $b } keys %{$counts};
    }

    if ($args{by_count}) {
        return sort { $counts->{$b} <=> $counts->{$a} || $a cmp $b } keys %{$counts};
    }

    if (my $order = $args{order}) {
        my %rank = map { $order->[$_] => $_ } 0 .. $#{$order};
        return sort {
            ($rank{$a} // 999) <=> ($rank{$b} // 999) || $a cmp $b
        } keys %{$counts};
    }

    return sort keys %{$counts};
}

sub _criteria_summary {
    my ($criteria) = @_;
    return 'all records' unless %{$criteria};

    my @parts;
    push @parts, "difficulty=$criteria->{difficulty}"
        if exists $criteria->{difficulty};
    push @parts, "highest_strategy=$criteria->{highest_strategy}"
        if exists $criteria->{highest_strategy};
    if (exists $criteria->{score}) {
        my $score = $criteria->{score};
        if (exists $score->{value}) {
            push @parts, "score=$score->{value}";
        }
        else {
            my @range;
            push @range, "min=$score->{min}" if exists $score->{min};
            push @range, "max=$score->{max}" if exists $score->{max};
            push @parts, 'score{' . join(',', @range) . '}';
        }
    }

    return join '; ', @parts;
}

sub _label_rank {
    my ($label) = @_;
    my %rank = (
        Trivial => 1,
        Easy    => 2,
        Medium  => 3,
        Hard    => 4,
        Expert  => 5,
        Master  => 6,
    );
    return $rank{$label} // 999;
}

sub _comma {
    my ($number) = @_;
    1 while $number =~ s/^(-?\d+)(\d{3})/$1,$2/;
    return $number;
}

sub _percent {
    my ($count, $total) = @_;
    return '0.00%' unless $total;
    return sprintf '%.2f%%', $count * 100 / $total;
}

sub _validate_integer {
    my (%args) = @_;
    my ($name) = keys %args;
    die "--$name must be an integer\n"
        unless defined($args{$name}) && $args{$name} =~ /\A-?\d+\z/;
}

sub _validate_positive_integer {
    my (%args) = @_;
    my ($name) = keys %args;
    die "--$name must be a positive integer\n"
        unless defined($args{$name}) && $args{$name} =~ /\A[1-9]\d*\z/;
}

sub _validate_non_negative_integer {
    my (%args) = @_;
    my ($name) = keys %args;
    die "--$name must be a non-negative integer\n"
        unless defined($args{$name}) && $args{$name} =~ /\A\d+\z/;
}

package _PRNG;

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

__END__

=head1 NAME

analyze-generation-difficulty.pl - sample generated-puzzle difficulty retention

=head1 SYNOPSIS

  bin/analyze-generation-difficulty.pl --base-difficulty Medium --clues 30 --samples 1000
  bin/analyze-generation-difficulty.pl --base-min-score 7 --clues 30 --samples 500 --seed 42
  bin/analyze-generation-difficulty.pl --base-difficulty Hard --clues 26 --samples 1000 --progress 50

=head1 DESCRIPTION

Samples canonical corpus records, applies seeded symmetry randomization and
controlled clue reveals, then solves and rates each generated puzzle. The
report shows how often a base difficulty bucket survives after revealing to the
requested clue count.

The script is diagnostic only. It does not search for an accepted target
puzzle; it measures the final difficulty distribution after generation.

=head1 OPTIONS

=over 4

=item B<--samples N>

Number of generated puzzles to sample. Defaults to 100.

=item B<--clues N>

Target clue count after controlled reveals. Defaults to 30.

=item B<--base-difficulty LABEL>

Restrict sampled source records to a corpus difficulty label.

=item B<--base-score N>, B<--base-min-score N>, B<--base-max-score N>

Restrict sampled source records by corpus difficulty score.

=item B<--base-highest-strategy NAME>

Restrict sampled source records by corpus highest required strategy.

=item B<--seed N>

Base deterministic sampling seed. Defaults to 1.

=item B<--corpus-file FILE>

Read a specific master corpus JSONL or JSONL.gz file.

=item B<--progress N>

Print progress to standard error every N samples. Defaults to 100. Use 0 to
disable progress output.

=item B<-h, --help>

Show this help.

=back
