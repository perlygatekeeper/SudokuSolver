package Sudoku::Corpus;

use strict;
use warnings;

use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use JSON::PP;
use Scalar::Util qw(blessed);

use Sudoku::Corpus::Query;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        file => $args{file} // _default_corpus_file(),
    }, $class;

    $self->_load;
    return $self;
}

sub file {
    my ($self) = @_;
    return $self->{file};
}

sub records {
    my ($self) = @_;
    return [ @{ $self->{records} } ];
}

sub count {
    my ($self) = @_;
    return scalar @{ $self->{records} };
}

sub find_by_canonical_id {
    my ($self, $canonical_id) = @_;
    return unless defined $canonical_id;
    return $self->{by_id}{$canonical_id};
}

sub find_by_id {
    my ($self, $canonical_id) = @_;
    return $self->find_by_canonical_id($canonical_id);
}

sub find_by_fingerprint {
    my ($self, $fingerprint) = @_;
    return unless defined $fingerprint;
    return $self->{by_fingerprint}{$fingerprint};
}

sub select {
    my ($self, %criteria) = @_;

    my @records = @{ $self->{records} };
    for my $criterion (sort keys %criteria) {
        my $value = $criteria{$criterion};
        my $field = _criterion_field($criterion);
        @records = grep {
            _matches_value(_record_value($_, $field), $value)
        } @records;
    }

    return Sudoku::Corpus::Query->new(records => \@records);
}

sub puzzles_by_difficulty {
    my ($self, $difficulty) = @_;
    return $self->select(difficulty => $difficulty);
}

sub puzzles_by_highest_strategy {
    my ($self, $strategy) = @_;
    return $self->select(highest_strategy => $strategy);
}

sub puzzles_with_symmetry {
    my ($self, $symmetry) = @_;
    return $self->select(symmetry => $symmetry);
}

sub puzzles_by_score {
    my ($self, $score) = @_;
    return $self->select(score => $score);
}

sub _load {
    my ($self) = @_;

    my $fh = _open_corpus_file($self->{file});

    my $json = JSON::PP->new;
    my (@records, %by_id, %by_fingerprint);
    my $previous_id;

    while (my $line = <$fh>) {
        next unless $line =~ /\S/;
        my $record = $json->decode($line);
        _validate_record($record, $self->{file});

        my $id = $record->{identity}{canonical_id};
        die "Canonical IDs are not in ascending order at '$id'\n"
            if defined($previous_id) && $id le $previous_id;
        $previous_id = $id;

        die "Duplicate canonical ID '$id' in '$self->{file}'\n"
            if exists $by_id{$id};
        $by_id{$id} = $record;

        my $fingerprint = $record->{identity}{fingerprint};
        die "Duplicate fingerprint '$fingerprint' in '$self->{file}'\n"
            if exists $by_fingerprint{$fingerprint};
        $by_fingerprint{$fingerprint} = $record;

        push @records, $record;
    }

    close $fh or die "Cannot close '$self->{file}': $!\n";
    die "No master corpus records were read from '$self->{file}'\n"
        unless @records;

    $self->{records} = \@records;
    $self->{by_id} = \%by_id;
    $self->{by_fingerprint} = \%by_fingerprint;

    return $self;
}

sub _default_corpus_file {
    my $jsonl = 'Puzzles/Master/sudoku17-master.jsonl';
    my $gzip = "$jsonl.gz";

    return $jsonl if -e $jsonl;
    return $gzip  if -e $gzip;
    return $jsonl;
}

sub _open_corpus_file {
    my ($file) = @_;

    if ($file =~ /\.gz\z/) {
        my $fh = IO::Uncompress::Gunzip->new($file)
            or die "Cannot open gzip corpus '$file': $GunzipError\n";
        return $fh;
    }

    open my $fh, '<:raw', $file
        or die "Cannot open '$file': $!\n";
    return $fh;
}

sub _validate_record {
    my ($record, $file) = @_;

    die "Malformed master corpus record in '$file'\n"
        unless ref($record) eq 'HASH'
            && ref($record->{identity}) eq 'HASH'
            && ref($record->{difficulty}) eq 'HASH'
            && ref($record->{pattern_symmetries}) eq 'ARRAY';

    die "Invalid canonical ID in '$file'\n"
        unless ($record->{identity}{canonical_id} // q{}) =~ /\A[A-Z0-9]+-\d{6,}\z/;
    die "Invalid fingerprint in '$file'\n"
        unless defined $record->{identity}{fingerprint};
    die "Invalid canonical puzzle in '$file'\n"
        unless ($record->{identity}{canonical_puzzle} // q{}) =~ /\A[0-9]{81}\z/;
    die "Invalid solution in '$file'\n"
        unless ($record->{solution} // q{}) =~ /\A[1-9]{81}\z/;

    return 1;
}

sub _criterion_field {
    my ($criterion) = @_;

    my %field = (
        id                       => 'canonical_id',
        canonical_id             => 'canonical_id',
        fingerprint              => 'fingerprint',
        puzzle                   => 'canonical_puzzle',
        canonical_puzzle         => 'canonical_puzzle',
        clue_count               => 'clue_count',
        difficulty               => 'difficulty_label',
        difficulty_label         => 'difficulty_label',
        label                    => 'difficulty_label',
        score                    => 'difficulty_score',
        difficulty_score         => 'difficulty_score',
        highest_strategy         => 'highest_strategy',
        strategy                 => 'highest_strategy',
        symmetry                 => 'pattern_symmetries',
        pattern_symmetry         => 'pattern_symmetries',
        pattern_symmetries       => 'pattern_symmetries',
    );

    die "Unknown corpus selection criterion '$criterion'\n"
        unless exists $field{$criterion};

    return $field{$criterion};
}

sub _record_value {
    my ($record, $field) = @_;

    return $record->{identity}{canonical_id} if $field eq 'canonical_id';
    return $record->{identity}{fingerprint} if $field eq 'fingerprint';
    return $record->{identity}{canonical_puzzle} if $field eq 'canonical_puzzle';
    return $record->{clue_count} if $field eq 'clue_count';
    return $record->{difficulty}{label} if $field eq 'difficulty_label';
    return $record->{difficulty}{score} if $field eq 'difficulty_score';
    return $record->{difficulty}{highest_strategy} if $field eq 'highest_strategy';
    return $record->{pattern_symmetries} if $field eq 'pattern_symmetries';

    die "Unknown corpus record field '$field'\n";
}

sub _matches_value {
    my ($actual, $expected) = @_;

    if (ref($expected) eq 'HASH') {
        return _matches_hash_spec($actual, $expected);
    }

    if (ref($expected) eq 'ARRAY') {
        return _matches_any($actual, @{$expected});
    }

    return _contains_or_equals($actual, $expected);
}

sub _matches_hash_spec {
    my ($actual, $spec) = @_;

    if (exists $spec->{not}) {
        return 0 if _matches_value($actual, $spec->{not});
    }
    if (exists $spec->{exclude}) {
        return 0 if _matches_value($actual, $spec->{exclude});
    }

    my $has_positive = 0;
    for my $key (qw(value eq in any min max gt gte lt lte)) {
        $has_positive ||= exists $spec->{$key};
    }
    return 1 unless $has_positive;

    my $ok = 1;
    $ok &&= _matches_value($actual, $spec->{value}) if exists $spec->{value};
    $ok &&= _matches_value($actual, $spec->{eq})    if exists $spec->{eq};
    $ok &&= _matches_any($actual, @{ _as_array($spec->{in}) }) if exists $spec->{in};
    $ok &&= _matches_any($actual, @{ _as_array($spec->{any}) }) if exists $spec->{any};

    my $number = _numeric_actual($actual);
    $ok &&= defined($number) && $number >= $spec->{min} if exists $spec->{min};
    $ok &&= defined($number) && $number <= $spec->{max} if exists $spec->{max};
    $ok &&= defined($number) && $number >  $spec->{gt}  if exists $spec->{gt};
    $ok &&= defined($number) && $number >= $spec->{gte} if exists $spec->{gte};
    $ok &&= defined($number) && $number <  $spec->{lt}  if exists $spec->{lt};
    $ok &&= defined($number) && $number <= $spec->{lte} if exists $spec->{lte};

    return $ok ? 1 : 0;
}

sub _matches_any {
    my ($actual, @expected) = @_;

    for my $item (@expected) {
        return 1 if _contains_or_equals($actual, $item);
    }

    return 0;
}

sub _contains_or_equals {
    my ($actual, $expected) = @_;

    return 0 unless defined $expected;

    if (ref($actual) eq 'ARRAY') {
        return (grep {
            defined $_ && $_ eq $expected
        } @{$actual}) ? 1 : 0;
    }

    return defined($actual) && $actual eq $expected ? 1 : 0;
}

sub _numeric_actual {
    my ($actual) = @_;
    return unless defined $actual && !ref($actual);
    return unless $actual =~ /\A-?\d+(?:\.\d+)?\z/;
    return 0 + $actual;
}

sub _as_array {
    my ($value) = @_;
    return $value if ref($value) eq 'ARRAY';
    return [ $value ];
}

1;
