use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';

use Sudoku::Corpus;
use Sudoku::Corpus::SQLiteCache;

my $tmpdir = tempdir(CLEANUP => 1);
my $source = File::Spec->catfile($tmpdir, 'master.jsonl');
my $cache_file = File::Spec->catfile($tmpdir, 'master.sqlite');

my $puzzle =
      '000000013'
    . '000800070'
    . '000502000'
    . '000400900'
    . '107000000'
    . '000000200'
    . '890000050'
    . '040000600'
    . '000010000';

my $solution =
      '278649513'
    . '956831472'
    . '314572896'
    . '532467981'
    . '167298345'
    . '489153267'
    . '893726154'
    . '741385629'
    . '625914738';

_write_source(
    $source,
    _record(
        canonical_id     => '17C-000001',
        fingerprint      => 'fp-001',
        difficulty_score => 2,
        difficulty_label => 'Easy',
        highest_strategy => 'Hidden Singles',
    ),
    _record(
        canonical_id       => '17C-000002',
        fingerprint        => 'fp-002',
        difficulty_score   => 7,
        difficulty_label   => 'Expert',
        highest_strategy   => 'Skyscraper',
        pattern_symmetries => ['diagonal'],
    ),
    _record(
        canonical_id     => '17C-000003',
        fingerprint      => 'fp-003',
        difficulty_score => 10,
        difficulty_label => 'Master',
        highest_strategy => 'AIC',
    ),
);

ok(
    !Sudoku::Corpus::SQLiteCache->is_current(
        source_file => $source,
        cache_file  => $cache_file,
    ),
    'missing cache is not current',
);

my $cache = Sudoku::Corpus::SQLiteCache->build(
    source_file => $source,
    cache_file  => $cache_file,
);

ok(-s $cache_file, 'cache file is built');
ok(
    Sudoku::Corpus::SQLiteCache->is_current(
        source_file => $source,
        cache_file  => $cache_file,
    ),
    'built cache is current',
);
is($cache->count, 3, 'cache counts records without reading JSONL directly');
is(
    $cache->find_by_id('17C-000002')->{difficulty}{highest_strategy},
    'Skyscraper',
    'cache finds records by canonical ID',
);
is(
    $cache->find_by_fingerprint('fp-003')->{identity}{canonical_id},
    '17C-000003',
    'cache finds records by fingerprint',
);
is(
    scalar @{ $cache->select(difficulty => 'Expert') },
    1,
    'cache selects by difficulty label',
);
is(
    scalar @{ $cache->select(score => { gte => 7 }) },
    2,
    'cache selects by score range',
);
is(
    scalar @{ $cache->select(highest_strategy => [ 'Skyscraper', 'AIC' ]) },
    2,
    'cache selects by highest-strategy set',
);

my $corpus = Sudoku::Corpus->new(
    file       => $source,
    cache_file => $cache_file,
);
ok($corpus->using_cache, 'corpus uses current SQLite cache automatically');
is($corpus->count, 3, 'corpus count delegates to cache');
is(
    $corpus->select(score => { min => 7 })->count,
    2,
    'corpus query delegates supported filters to cache',
);
is(
    $corpus->select(symmetry => 'diagonal')->first->{identity}{canonical_id},
    '17C-000002',
    'corpus falls back to JSONL filtering for pattern-symmetry criteria',
);

sleep 1;
_write_source(
    $source,
    _record(
        canonical_id     => '17C-000001',
        fingerprint      => 'fp-001',
        difficulty_score => 2,
        difficulty_label => 'Easy',
        highest_strategy => 'Hidden Singles',
    ),
);

ok(
    !Sudoku::Corpus::SQLiteCache->is_current(
        source_file => $source,
        cache_file  => $cache_file,
    ),
    'cache is stale when source metadata changes',
);

my $uncached = Sudoku::Corpus->new(
    file       => $source,
    cache_file => $cache_file,
);
ok(!$uncached->using_cache, 'corpus ignores stale cache');
is($uncached->count, 1, 'corpus falls back to current source data');

done_testing();

sub _write_source {
    my ($file, @records) = @_;

    open my $out, '>:raw', $file or die "Cannot create '$file': $!";
    my $json = JSON::PP->new->canonical(1);
    print {$out} $json->encode($_), "\n" for @records;
    close $out;
}

sub _record {
    my (%args) = @_;

    return {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => $args{canonical_id},
            fingerprint      => $args{fingerprint},
            canonical_puzzle => $puzzle,
        },
        solution => $solution,
        clue_count => 17,
        canonicalization => {
            scheme         => 'SudokuSolver',
            scheme_version => '1.0',
        },
        difficulty => {
            scheme           => 'SudokuSolver',
            scheme_version   => '2.7',
            score            => $args{difficulty_score},
            label            => $args{difficulty_label},
            highest_strategy => $args{highest_strategy},
        },
        pattern_symmetries => $args{pattern_symmetries} // [],
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $puzzle,
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}
