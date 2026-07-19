#!/usr/bin/env perl

use strict;
use warnings;
use v5.34;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

use Solver;
use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Corpus;

my $samples = 1000;
my $runs = 10;
my $seed = 1;
my $corpus_file;
my $output = 'generation-difficulty-drops.csv';
my $sample_mode = 'stratified';
my $progress = 10;
my $max_reveals;
my $help;

GetOptions(
    'samples=i'     => \$samples,
    'runs=i'        => \$runs,
    'seed=i'        => \$seed,
    'corpus-file=s' => \$corpus_file,
    'output=s'      => \$output,
    'sample-mode=s' => \$sample_mode,
    'progress=i'    => \$progress,
    'max-reveals=i' => \$max_reveals,
    'help|h'        => \$help,
) or pod2usage(2);

pod2usage(0) if $help;

_validate_positive_integer(samples => $samples);
_validate_positive_integer(runs => $runs);
_validate_integer(seed => $seed);
_validate_non_negative_integer(progress => $progress);
_validate_non_negative_integer('max-reveals' => $max_reveals)
    if defined $max_reveals;
die "--sample-mode must be 'stratified' or 'random'\n"
    unless $sample_mode =~ /\A(?:stratified|random)\z/;

my $corpus = Sudoku::Corpus->new(
    defined($corpus_file) ? (file => $corpus_file) : (),
);
my $records = _eligible_records($corpus->records);
die "No corpus records above Trivial difficulty are available\n"
    unless @{$records};

my $rng = _PRNG->new($seed);
my $sampled_records = _sample_records(
    records => $records,
    samples => $samples,
    mode    => $sample_mode,
    rng     => $rng,
);

open my $csv, '>:encoding(UTF-8)', $output
    or die "Cannot write '$output': $!\n";
_write_csv_row($csv, qw(
    sample_index run_index canonical_id source_ordinal base_label base_score
    base_highest_strategy base_clues reveal_seed target_label reveals_to_drop
    clue_count_at_drop final_label final_score final_highest_strategy status
));

my %sampled_label_count;
my %drop_summary;
my %terminal_label_count;
my $rating_version = q{};
my ($observed_runs, $failed_runs) = (0, 0);

for my $sample_index (1 .. @{$sampled_records}) {
    my $record = $sampled_records->[$sample_index - 1];
    my $base = $record->{difficulty} // {};
    my $base_label = $base->{label} // 'Unknown';
    my $base_score = $base->{score} // q{};
    my $base_rank = _label_rank($base_label);
    my $canonical_id = $record->{identity}{canonical_id} // q{};
    my $source_ordinal = $record->{provenance}{source_ordinal} // q{};
    my $base_strategy = $base->{highest_strategy} // 'none';
    my $base_clues = clue_count($record->{identity}{canonical_puzzle});

    $sampled_label_count{$base_label}++;

    for my $run_index (1 .. $runs) {
        my $reveal_seed = $seed
            + 1_000_003 * $sample_index
            + 2_000_003 * $run_index;

        my $result = eval {
            _measure_run(
                record      => $record,
                base_rank   => $base_rank,
                reveal_seed => $reveal_seed,
                max_reveals => $max_reveals,
            );
        };

        if (!$result) {
            warn "Sample $sample_index run $run_index failed: $@";
            $failed_runs++;
            next;
        }

        $observed_runs++;
        $rating_version ||= $result->{rating_version};
        $terminal_label_count{ $result->{terminal_label} }++;

        for my $row (@{ $result->{drops} }) {
            my $status = defined($row->{reveals_to_drop}) ? 'reached' : 'unreached';
            my $key = join "\t", $base_label, $row->{target_label};
            $drop_summary{$key}{runs}++;
            if ($status eq 'reached') {
                $drop_summary{$key}{reached}++;
                push @{ $drop_summary{$key}{reveals} }, $row->{reveals_to_drop};
            }

            _write_csv_row(
                $csv,
                $sample_index,
                $run_index,
                $canonical_id,
                $source_ordinal,
                $base_label,
                $base_score,
                $base_strategy,
                $base_clues,
                $reveal_seed,
                $row->{target_label},
                $row->{reveals_to_drop} // q{},
                $row->{clue_count_at_drop} // q{},
                $row->{final_label} // q{},
                $row->{final_score} // q{},
                $row->{final_highest_strategy} // q{},
                $status,
            );
        }
    }

    if ($progress && $sample_index % $progress == 0) {
        printf STDERR "Processed %d / %d sampled puzzles\n",
            $sample_index,
            scalar @{$sampled_records};
    }
}

close $csv or die "Cannot close '$output': $!\n";

_print_report(
    corpus               => $corpus,
    output               => $output,
    samples              => scalar @{$sampled_records},
    runs                 => $runs,
    observed_runs        => $observed_runs,
    failed_runs          => $failed_runs,
    seed                 => $seed,
    sample_mode          => $sample_mode,
    rating_version       => $rating_version || 'unknown',
    max_reveals          => $max_reveals,
    sampled_label_count  => \%sampled_label_count,
    terminal_label_count => \%terminal_label_count,
    drop_summary         => \%drop_summary,
);

exit($failed_runs ? 1 : 0);

sub _eligible_records {
    my ($records) = @_;

    my @eligible = grep {
        my $rank = _label_rank($_->{difficulty}{label} // 'Unknown');
        $rank > _label_rank('Trivial') && $rank < _label_rank('Unknown')
    } @{$records};

    return \@eligible;
}

sub _sample_records {
    my (%args) = @_;

    return _sample_random(%args) if $args{mode} eq 'random';
    return _sample_stratified(%args);
}

sub _sample_random {
    my (%args) = @_;

    my @records = @{ $args{records} };
    _shuffle_in_place($args{rng}, \@records);
    return _take_with_reuse(\@records, $args{samples}, $args{rng});
}

sub _sample_stratified {
    my (%args) = @_;

    my %by_label;
    for my $record (@{ $args{records} }) {
        push @{ $by_label{ $record->{difficulty}{label} // 'Unknown' } }, $record;
    }

    my @labels = sort {
        _label_rank($b) <=> _label_rank($a) || $a cmp $b
    } keys %by_label;

    my $per_label = int($args{samples} / @labels);
    my $remainder = $args{samples} % @labels;
    my @sampled;

    for my $index (0 .. $#labels) {
        my $label = $labels[$index];
        my $target = $per_label + ($index < $remainder ? 1 : 0);
        my @bucket = @{ $by_label{$label} };
        _shuffle_in_place($args{rng}, \@bucket);
        push @sampled, @{ _take_with_reuse(\@bucket, $target, $args{rng}) };
    }

    _shuffle_in_place($args{rng}, \@sampled);
    return \@sampled;
}

sub _take_with_reuse {
    my ($records, $wanted, $rng) = @_;

    my @picked;
    while (@picked < $wanted) {
        my @batch = @{$records};
        _shuffle_in_place($rng, \@batch) if @picked;
        my $remaining = $wanted - @picked;
        my $last_index = $remaining - 1 < $#batch ? $remaining - 1 : $#batch;
        push @picked, @batch[0 .. $last_index];
    }

    splice @picked, $wanted if @picked > $wanted;
    return \@picked;
}

sub _measure_run {
    my (%args) = @_;

    my $record = $args{record};
    my $base_rank = $args{base_rank};
    my $puzzle = $record->{identity}{canonical_puzzle};
    my $solution = $record->{solution};
    my @empty_cells = grep { substr($puzzle, $_, 1) eq '0' } 0 .. 80;
    my $limit = defined($args{max_reveals}) && $args{max_reveals} < @empty_cells
        ? $args{max_reveals}
        : scalar @empty_cells;

    my $rng = _PRNG->new($args{reveal_seed});
    _shuffle_in_place($rng, \@empty_cells);

    my @targets = map {
        +{
            rank => $_,
            label => _rank_label($_),
        }
    } reverse _label_rank('Trivial') .. $base_rank - 1;
    my @pending = @targets;
    my @drops;
    my $rating_version = q{};
    my $terminal_label = $record->{difficulty}{label} // 'Unknown';
    my @cells = split //, $puzzle;

    for my $reveals (1 .. $limit) {
        my $cell_index = $empty_cells[$reveals - 1];
        $cells[$cell_index] = substr($solution, $cell_index, 1);
        my $current_puzzle = join q{}, @cells;
        my $difficulty = _rate_puzzle($current_puzzle);
        $rating_version ||= $difficulty->rating_version;
        $terminal_label = $difficulty->label;
        my $current_rank = _label_rank($terminal_label);

        my @still_pending;
        for my $target (@pending) {
            if ($current_rank <= $target->{rank}) {
                push @drops, {
                    target_label           => $target->{label},
                    reveals_to_drop        => $reveals,
                    clue_count_at_drop     => clue_count($current_puzzle),
                    final_label            => $difficulty->label,
                    final_score            => $difficulty->score,
                    final_highest_strategy => $difficulty->highest_strategy // 'none',
                };
            }
            else {
                push @still_pending, $target;
            }
        }
        @pending = @still_pending;
        last if $current_rank <= _label_rank('Trivial');
    }

    for my $target (@pending) {
        push @drops, {
            target_label => $target->{label},
        };
    }

    return {
        drops          => \@drops,
        terminal_label => $terminal_label,
        rating_version => $rating_version,
    };
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

sub _print_report {
    my (%args) = @_;

    say 'Reveal Difficulty Drop Statistics';
    say '=================================';
    say q{};
    say 'Corpus file:       ' . $args{corpus}->file;
    say 'Corpus cache:      ' . ($args{corpus}->using_cache ? 'yes' : 'no');
    say 'CSV output:        ' . $args{output};
    say 'Sample mode:       ' . $args{sample_mode};
    say 'Sampled puzzles:   ' . _comma($args{samples});
    say 'Runs per puzzle:   ' . _comma($args{runs});
    say 'Observed runs:     ' . _comma($args{observed_runs});
    say 'Failed runs:       ' . _comma($args{failed_runs});
    say 'Seed:              ' . $args{seed};
    say 'Rating version:    ' . $args{rating_version};
    say 'Max reveals:       ' . (defined($args{max_reveals}) ? $args{max_reveals} : 'until Trivial or full grid');
    say q{};

    _print_count_table(
        title => 'Sampled Base Difficulty Labels',
        counts => $args{sampled_label_count},
        total => $args{samples},
        order => [ qw(Trivial Easy Medium Hard Expert Master Unrated Unknown) ],
    );
    _print_count_table(
        title => 'Terminal Difficulty Labels',
        counts => $args{terminal_label_count},
        total => $args{observed_runs},
        order => [ qw(Unrated Trivial Easy Medium Hard Expert Master Unknown) ],
    );
    _print_drop_summary($args{drop_summary});
}

sub _print_count_table {
    my (%args) = @_;

    say $args{title};
    say '-' x length($args{title});
    say '| Value | Count | Share |';
    say '| --- | ---: | ---: |';

    for my $key (_ordered_keys(%args)) {
        my $count = $args{counts}{$key} // 0;
        next unless $count;
        printf "| %s | %s | %s |\n",
            $key,
            _comma($count),
            _percent($count, $args{total});
    }
    say q{};
}

sub _print_drop_summary {
    my ($summary) = @_;

    say 'Reveal Counts To Difficulty Drops';
    say '----------------------------------';
    say '| Base | Target | Runs | Reached | Share | Min | Median | P90 | Max | Mean |';
    say '| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |';

    for my $key (sort {
        my ($a_base, $a_target) = split /\t/, $a, 2;
        my ($b_base, $b_target) = split /\t/, $b, 2;
        _label_rank($b_base) <=> _label_rank($a_base)
            || _label_rank($b_target) <=> _label_rank($a_target)
            || $a cmp $b;
    } keys %{$summary}) {
        my ($base, $target) = split /\t/, $key, 2;
        my $runs = $summary->{$key}{runs} // 0;
        my $reached = $summary->{$key}{reached} // 0;
        my @reveals = sort { $a <=> $b } @{ $summary->{$key}{reveals} // [] };

        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n",
            $base,
            $target,
            _comma($runs),
            _comma($reached),
            _percent($reached, $runs),
            @reveals ? $reveals[0] : q{},
            @reveals ? _percentile(\@reveals, 0.50) : q{},
            @reveals ? _percentile(\@reveals, 0.90) : q{},
            @reveals ? $reveals[-1] : q{},
            @reveals ? sprintf('%.2f', _mean(\@reveals)) : q{};
    }
    say q{};
}

sub _ordered_keys {
    my (%args) = @_;
    my $counts = $args{counts};

    if (my $order = $args{order}) {
        my %rank = map { $order->[$_] => $_ } 0 .. $#{$order};
        return sort {
            ($rank{$a} // 999) <=> ($rank{$b} // 999) || $a cmp $b
        } keys %{$counts};
    }

    return sort keys %{$counts};
}

sub _write_csv_row {
    my ($fh, @values) = @_;
    say {$fh} join q{,}, map { _csv_escape($_) } @values;
}

sub _csv_escape {
    my ($value) = @_;
    $value = q{} unless defined $value;
    $value =~ s/"/""/g;
    return qq{"$value"} if $value =~ /[",\r\n]/;
    return $value;
}

sub _shuffle_in_place {
    my ($rng, $items) = @_;

    for (my $index = $#{$items}; $index > 0; $index--) {
        my $swap = $rng->integer($index + 1);
        @{$items}[$index, $swap] = @{$items}[$swap, $index];
    }
}

sub _label_rank {
    my ($label) = @_;
    my %rank = (
        Unrated => 0,
        Trivial => 1,
        Easy    => 2,
        Medium  => 3,
        Hard    => 4,
        Expert  => 5,
        Master  => 6,
    );
    return $rank{$label} // 999;
}

sub _rank_label {
    my ($rank) = @_;
    my %label = (
        1 => 'Trivial',
        2 => 'Easy',
        3 => 'Medium',
        4 => 'Hard',
        5 => 'Expert',
        6 => 'Master',
    );
    return $label{$rank} // 'Unknown';
}

sub _percentile {
    my ($values, $fraction) = @_;
    return q{} unless @{$values};
    my $index = int(($#{$values}) * $fraction + 0.5);
    return $values->[$index];
}

sub _mean {
    my ($values) = @_;
    my $sum = 0;
    $sum += $_ for @{$values};
    return $sum / @{$values};
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

analyze-reveal-difficulty-drops.pl - measure clue reveals needed for difficulty drops

=head1 SYNOPSIS

  tools/analyze-reveal-difficulty-drops.pl
  tools/analyze-reveal-difficulty-drops.pl --samples 1000 --runs 10 --output drops.csv
  tools/analyze-reveal-difficulty-drops.pl --samples 25 --runs 2 --max-reveals 20

=head1 DESCRIPTION

Samples corpus puzzles above Trivial difficulty. For each puzzle, the script
runs several seeded reveal orders, adds solution clues one at a time, rates the
new puzzle after each reveal, and records the first reveal count at which each
easier difficulty label is reached.

The default sample mode is stratified, so the sample is spread across available
base difficulty labels. Use C<--sample-mode random> to sample from the eligible
corpus distribution directly.

=head1 OPTIONS

=over 4

=item B<--samples N>

Number of corpus puzzles to sample. Defaults to 1000.

=item B<--runs N>

Number of reveal orders to test for each sampled puzzle. Defaults to 10.

=item B<--seed N>

Deterministic sampling seed. Defaults to 1.

=item B<--corpus-file FILE>

Read a specific master corpus JSONL or JSONL.gz file.

=item B<--output FILE>

Write raw observations as CSV. Defaults to generation-difficulty-drops.csv.

=item B<--sample-mode MODE>

Either C<stratified> or C<random>. Defaults to C<stratified>.

=item B<--progress N>

Print progress to standard error every N sampled puzzles. Defaults to 10. Use
0 to disable progress output.

=item B<--max-reveals N>

Stop each run after at most N reveals. Mostly useful for pilot runs and tests.

=item B<-h, --help>

Show this help.

=back
