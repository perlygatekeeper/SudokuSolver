use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku::Corpus;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');

my @records = (
    _record(
        id => '17C-000001',
        fingerprint => 'fp-001',
        puzzle => ('0' x 64) . ('1' x 17),
        solution => '1' x 81,
        label => 'Easy',
        score => 2,
        strategy => 'Hidden Singles',
        symmetries => [],
    ),
    _record(
        id => '17C-000002',
        fingerprint => 'fp-002',
        puzzle => ('0' x 64) . ('2' x 17),
        solution => '2' x 81,
        label => 'Hard',
        score => 4,
        strategy => 'Naked Pairs',
        symmetries => [ 'rotation-180' ],
    ),
    _record(
        id => '17C-000003',
        fingerprint => 'fp-003',
        puzzle => ('0' x 64) . ('3' x 17),
        solution => '3' x 81,
        label => 'Expert',
        score => 7,
        strategy => 'Skyscraper',
        symmetries => [],
    ),
    _record(
        id => '17C-000004',
        fingerprint => 'fp-004',
        puzzle => ('0' x 64) . ('4' x 17),
        solution => '4' x 81,
        label => 'Master',
        score => 11,
        strategy => 'Digit Forcing Chains',
        symmetries => [ 'reflection-main-diagonal' ],
    ),
);

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
my $json = JSON::PP->new->canonical(1);
print {$out} $json->encode($_), "\n" for @records;
close $out;

my $corpus = Sudoku::Corpus->new(file => $master);
is $corpus->count, 4, 'corpus loads JSONL records';
is $corpus->file, $master, 'corpus remembers source file';

is $corpus->find_by_canonical_id('17C-000002')->{identity}{fingerprint},
    'fp-002', 'lookup by canonical ID works';
is $corpus->find_by_id('17C-000002')->{identity}{fingerprint},
    'fp-002', 'lookup by ID alias works';
is $corpus->find_by_fingerprint('fp-003')->{identity}{canonical_id},
    '17C-000003', 'lookup by fingerprint works';
ok !defined($corpus->find_by_id('17C-999999')),
    'missing canonical ID returns undef';

is $corpus->select(difficulty => 'Hard')->count, 1,
    'select filters by difficulty label';
is $corpus->select(score => { min => 4, max => 7 })->count, 2,
    'select supports numeric score ranges';
is_deeply(
    $corpus->select(
        difficulty       => [ 'Hard', 'Master' ],
        highest_strategy => { not => 'Naked Pairs' },
    )->ids,
    [ '17C-000004' ],
    'select combines AND criteria with lists and exclusions',
);
is_deeply(
    $corpus->select(symmetry => 'rotation-180')->ids,
    [ '17C-000002' ],
    'select filters by pattern symmetry membership',
);
is_deeply(
    $corpus->select(id => { in => [ '17C-000001', '17C-000004' ] })->ids,
    [ '17C-000001', '17C-000004' ],
    'select supports canonical ID sets',
);
is_deeply(
    $corpus->select(fingerprint => { exclude => [ 'fp-001', 'fp-002' ] })->ids,
    [ '17C-000003', '17C-000004' ],
    'select supports fingerprint exclusions',
);

is_deeply(
    $corpus->select(score => { gte => 4 })
        ->sort_by('score', direction => 'desc')
        ->limit(2)
        ->ids,
    [ '17C-000004', '17C-000003' ],
    'query results can be sorted and limited',
);

my $random_a = $corpus->select(score => { gte => 2 })->random(seed => 42)->ids;
my $random_b = $corpus->select(score => { gte => 2 })->random(seed => 42)->ids;
my $random_c = $corpus->select(score => { gte => 2 })->random(seed => 43)->ids;
is_deeply $random_a, $random_b,
    'deterministic random selection is stable for the same seed';
isnt join(',', @$random_a), join(',', @$random_c),
    'different random seeds can produce different order';
is scalar @{ $corpus->select(score => { gte => 2 })->random(seed => 42, limit => 2)->ids },
    2, 'random selection supports limits';

is_deeply $corpus->puzzles_by_difficulty('Easy')->ids, [ '17C-000001' ],
    'difficulty convenience helper delegates to select';
is_deeply $corpus->puzzles_by_highest_strategy('Naked Pairs')->ids, [ '17C-000002' ],
    'highest-strategy convenience helper delegates to select';
is_deeply $corpus->puzzles_with_symmetry('reflection-main-diagonal')->ids, [ '17C-000004' ],
    'symmetry convenience helper delegates to select';
is_deeply $corpus->puzzles_by_score({ min => 7 })->ids,
    [ '17C-000003', '17C-000004' ],
    'score convenience helper delegates to select';

for my $case (
    [ sub { $corpus->select(unknown => 'x') }, qr/Unknown corpus selection criterion/, 'unknown criterion is rejected' ],
    [ sub { $corpus->select(score => { min => 4 })->sort_by('unknown') }, qr/Unknown corpus sort field/, 'unknown sort field is rejected' ],
    [ sub { $corpus->select(score => 4)->limit(-1) }, qr/non-negative integer/, 'negative limit is rejected' ],
    [ sub { $corpus->select(score => 4)->random(seed => 'abc') }, qr/integer seed/, 'invalid random seed is rejected' ],
) {
    my ($callback, $pattern, $name) = @{$case};
    my $ok = eval { $callback->(); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name with useful error";
}

done_testing();

sub _record {
    my (%args) = @_;

    return {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => $args{id},
            fingerprint      => $args{fingerprint},
            canonical_puzzle => $args{puzzle},
        },
        solution => $args{solution},
        clue_count => 17,
        canonicalization => {
            scheme         => 'SudokuSolver',
            scheme_version => '1.0',
        },
        difficulty => {
            scheme           => 'SudokuSolver',
            scheme_version   => '2.7',
            score            => $args{score},
            label            => $args{label},
            highest_strategy => $args{strategy},
        },
        pattern_symmetries => $args{symmetries},
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $args{puzzle},
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}
