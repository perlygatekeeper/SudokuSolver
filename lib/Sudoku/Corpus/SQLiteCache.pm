package Sudoku::Corpus::SQLiteCache;

use strict;
use warnings;

use DBI;
use IO::Uncompress::Gunzip qw($GunzipError);
use JSON::PP;

our $SCHEMA_VERSION = 1;

sub new {
    my ($class, %args) = @_;

    die "cache file is required\n"
        unless defined $args{file} && length $args{file};

    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$args{file}",
        q{},
        q{},
        {
            RaiseError     => 1,
            PrintError     => 0,
            AutoCommit     => 1,
            sqlite_unicode => 1,
        },
    );

    return bless {
        file => $args{file},
        dbh  => $dbh,
        json => JSON::PP->new,
    }, $class;
}

sub file {
    my ($self) = @_;
    return $self->{file};
}

sub is_current {
    my ($class, %args) = @_;

    my $cache_file = $args{cache_file};
    my $source_file = $args{source_file};
    return 0 unless defined $cache_file && -e $cache_file;
    return 0 unless defined $source_file && -e $source_file;

    my $cache = eval { $class->new(file => $cache_file) };
    return 0 if !$cache;

    my @stat = stat $source_file;
    return 0 unless @stat;

    my $ok = eval {
        ($cache->_metadata('schema_version') // q{}) eq "$SCHEMA_VERSION"
            && ($cache->_metadata('source_size') // q{}) eq "$stat[7]"
            && ($cache->_metadata('source_mtime') // q{}) eq "$stat[9]"
            && $cache->count > 0;
    };

    return $ok ? 1 : 0;
}

sub build {
    my ($class, %args) = @_;

    my $source_file = $args{source_file};
    my $cache_file = $args{cache_file};
    die "source_file is required\n"
        unless defined $source_file && length $source_file;
    die "cache_file is required\n"
        unless defined $cache_file && length $cache_file;

    my $tmp_file = "$cache_file.tmp";
    unlink $tmp_file if -e $tmp_file;

    my $cache = $class->new(file => $tmp_file);
    my $dbh = $cache->{dbh};
    my $json = JSON::PP->new;

    $dbh->do('PRAGMA journal_mode = OFF');
    $dbh->do('PRAGMA synchronous = OFF');
    $dbh->do('CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    $dbh->do(<<'SQL');
CREATE TABLE records (
    ordinal INTEGER PRIMARY KEY,
    canonical_id TEXT NOT NULL UNIQUE,
    fingerprint TEXT NOT NULL UNIQUE,
    canonical_puzzle TEXT NOT NULL,
    solution TEXT NOT NULL,
    clue_count INTEGER NOT NULL,
    difficulty_label TEXT NOT NULL,
    difficulty_score INTEGER NOT NULL,
    highest_strategy TEXT,
    json TEXT NOT NULL
)
SQL

    my $insert = $dbh->prepare(<<'SQL');
INSERT INTO records (
    ordinal,
    canonical_id,
    fingerprint,
    canonical_puzzle,
    solution,
    clue_count,
    difficulty_label,
    difficulty_score,
    highest_strategy,
    json
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL

    my $fh = _open_source_file($source_file);
    my ($count, $previous_id) = (0, undef);

    $dbh->begin_work;
    while (my $line = <$fh>) {
        next unless $line =~ /\S/;
        my $record = $json->decode($line);
        _validate_record($record, $source_file);

        my $id = $record->{identity}{canonical_id};
        die "Canonical IDs are not in ascending order at '$id'\n"
            if defined($previous_id) && $id le $previous_id;
        $previous_id = $id;
        ++$count;

        $insert->execute(
            $count,
            $id,
            $record->{identity}{fingerprint},
            $record->{identity}{canonical_puzzle},
            $record->{solution},
            0 + ($record->{clue_count} // 0),
            $record->{difficulty}{label},
            0 + $record->{difficulty}{score},
            $record->{difficulty}{highest_strategy},
            $json->canonical(1)->encode($record),
        );
    }
    close $fh or die "Cannot close '$source_file': $!\n";
    die "No master corpus records were read from '$source_file'\n"
        unless $count;

    $dbh->do('CREATE INDEX idx_records_clue_count ON records(clue_count)');
    $dbh->do('CREATE INDEX idx_records_difficulty_label ON records(difficulty_label)');
    $dbh->do('CREATE INDEX idx_records_difficulty_score ON records(difficulty_score)');
    $dbh->do('CREATE INDEX idx_records_highest_strategy ON records(highest_strategy)');

    my @stat = stat $source_file;
    die "Cannot stat '$source_file': $!\n" unless @stat;

    my $metadata = $dbh->prepare('INSERT INTO metadata (key, value) VALUES (?, ?)');
    $metadata->execute(schema_version => $SCHEMA_VERSION);
    $metadata->execute(source_file    => $source_file);
    $metadata->execute(source_size    => "$stat[7]");
    $metadata->execute(source_mtime   => "$stat[9]");
    $metadata->execute(record_count   => "$count");
    $dbh->commit;
    $dbh->disconnect;

    rename $tmp_file, $cache_file
        or die "Cannot move '$tmp_file' to '$cache_file': $!\n";

    return $class->new(file => $cache_file);
}

sub count {
    my ($self) = @_;
    return 0 + $self->{dbh}->selectrow_array('SELECT COUNT(*) FROM records');
}

sub records {
    my ($self) = @_;
    return $self->_records_for_sql('SELECT json FROM records ORDER BY ordinal');
}

sub find_by_canonical_id {
    my ($self, $canonical_id) = @_;
    return unless defined $canonical_id;
    return $self->_record_for_sql(
        'SELECT json FROM records WHERE canonical_id = ?',
        $canonical_id,
    );
}

sub find_by_id {
    my ($self, $canonical_id) = @_;
    return $self->find_by_canonical_id($canonical_id);
}

sub find_by_fingerprint {
    my ($self, $fingerprint) = @_;
    return unless defined $fingerprint;
    return $self->_record_for_sql(
        'SELECT json FROM records WHERE fingerprint = ?',
        $fingerprint,
    );
}

sub select {
    my ($self, %criteria) = @_;

    my (@where, @bind);
    for my $criterion (sort keys %criteria) {
        my $column = _criterion_column($criterion);
        return unless defined $column;

        my ($sql, @values) = _sql_for_spec($column, $criteria{$criterion});
        return unless defined $sql;

        push @where, "($sql)";
        push @bind, @values;
    }

    my $sql = 'SELECT json FROM records';
    $sql .= ' WHERE ' . join(' AND ', @where) if @where;
    $sql .= ' ORDER BY ordinal';

    return $self->_records_for_sql($sql, @bind);
}

sub _metadata {
    my ($self, $key) = @_;
    return $self->{dbh}->selectrow_array(
        'SELECT value FROM metadata WHERE key = ?',
        undef,
        $key,
    );
}

sub _record_for_sql {
    my ($self, $sql, @bind) = @_;
    my $text = $self->{dbh}->selectrow_array($sql, undef, @bind);
    return unless defined $text;
    return $self->{json}->decode($text);
}

sub _records_for_sql {
    my ($self, $sql, @bind) = @_;

    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute(@bind);

    my @records;
    while (my ($text) = $sth->fetchrow_array) {
        push @records, $self->{json}->decode($text);
    }

    return \@records;
}

sub _criterion_column {
    my ($criterion) = @_;

    my %column = (
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
    );

    return $column{$criterion};
}

sub _sql_for_spec {
    my ($column, $spec) = @_;

    if (ref($spec) eq 'HASH') {
        my (@where, @bind);

        for my $key (qw(value eq)) {
            if (exists $spec->{$key}) {
                my ($sql, @values) = _sql_for_spec($column, $spec->{$key});
                return unless defined $sql;
                push @where, $sql;
                push @bind, @values;
            }
        }

        for my $key (qw(in any)) {
            if (exists $spec->{$key}) {
                my ($sql, @values) = _sql_for_spec($column, _as_array($spec->{$key}));
                return unless defined $sql;
                push @where, $sql;
                push @bind, @values;
            }
        }

        my %operator = (
            min => '>=',
            gte => '>=',
            gt  => '>',
            max => '<=',
            lte => '<=',
            lt  => '<',
        );
        for my $key (qw(min gte gt max lte lt)) {
            next unless exists $spec->{$key};
            push @where, "$column $operator{$key} ?";
            push @bind, $spec->{$key};
        }

        for my $key (qw(not exclude)) {
            next unless exists $spec->{$key};
            my ($sql, @values) = _sql_for_spec($column, $spec->{$key});
            return unless defined $sql;
            push @where, "NOT ($sql)";
            push @bind, @values;
        }

        return ('1 = 1') unless @where;
        return (join(' AND ', map { "($_)" } @where), @bind);
    }

    if (ref($spec) eq 'ARRAY') {
        return ('0 = 1') unless @{$spec};
        my $placeholders = join ', ', ('?') x @{$spec};
        return ("$column IN ($placeholders)", @{$spec});
    }

    return unless defined $spec;
    return ("$column = ?", $spec);
}

sub _as_array {
    my ($value) = @_;
    return $value if ref($value) eq 'ARRAY';
    return [$value];
}

sub _open_source_file {
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
    die "Invalid difficulty score in '$file'\n"
        unless defined($record->{difficulty}{score})
            && $record->{difficulty}{score} =~ /\A\d+\z/;
    die "Invalid difficulty label in '$file'\n"
        unless defined $record->{difficulty}{label};

    return 1;
}

1;
