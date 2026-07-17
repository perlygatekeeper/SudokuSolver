use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku::Corpus;
use Sudoku::Generator;
use Sudoku::Symmetry;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');

my @records = (
    _record(
        id          => '17C-000001',
        fingerprint => 'fp-001',
        puzzle      => '123000000'
                    . '000400000'
                    . '000000500'
                    . '600000000'
                    . '000070000'
                    . '000000008'
                    . '000000090'
                    . '000001000'
                    . '000000000',
        solution    => _fixture_solution(
            '123000000'
          . '000400000'
          . '000000500'
          . '600000000'
          . '000070000'
          . '000000008'
          . '000000090'
          . '000001000'
          . '000000000',
        ),
        label       => 'Easy',
        score       => 2,
    ),
    _record(
        id          => '17C-000002',
        fingerprint => 'fp-002',
        puzzle      => '100000000'
                    . '020000000'
                    . '003000000'
                    . '000400000'
                    . '000050000'
                    . '000006000'
                    . '000000700'
                    . '000000080'
                    . '000000009',
        solution    => _fixture_solution(
            '100000000'
          . '020000000'
          . '003000000'
          . '000400000'
          . '000050000'
          . '000006000'
          . '000000700'
          . '000000080'
          . '000000009',
        ),
        label       => 'Master',
        score       => 11,
    ),
);

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
my $json = JSON::PP->new->canonical(1);
print {$out} $json->encode($_), "\n" for @records;
close $out;

my $corpus = Sudoku::Corpus->new(file => $master);
my $generator = Sudoku::Generator->new(corpus => $corpus);

my $generated = $generator->symmetry_randomized(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
);
isa_ok $generated, 'Sudoku::GeneratedPuzzle';
like $generated->canonical_id, qr/\A17C-00000[12]\z/,
    'generated puzzle records canonical identity';
is $generated->corpus_seed, 7, 'generated puzzle records corpus seed';
is $generated->symmetry_seed, 123456789,
    'generated puzzle records symmetry seed';
is $generated->transform_shorthand,
    'D=746123859;B=102;R=210|210|120;S=102;C=021|012|102',
    'generated puzzle records explicit transform shorthand';

my $replayed_transform = Sudoku::Symmetry->from_shorthand(
    $generated->transform_shorthand,
);
is $replayed_transform->apply_puzzle($generated->canonical_puzzle),
    $generated->puzzle,
    'stored transform replays generated puzzle from canonical puzzle';
is $replayed_transform->apply_puzzle($generated->canonical_solution),
    $generated->solution,
    'stored transform replays generated solution from canonical solution';

for my $index (0 .. 80) {
    my $clue = substr($generated->puzzle, $index, 1);
    next if $clue eq '0';
    is substr($generated->solution, $index, 1), $clue,
        'generated solution preserves every generated clue';
}

my $same = $generator->symmetry_randomized(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
);
is $same->canonical_id, $generated->canonical_id,
    'same corpus seed selects same canonical record';
is $same->puzzle, $generated->puzzle,
    'same seeds produce same transformed puzzle';
is $same->solution, $generated->solution,
    'same seeds produce same transformed solution';

my $different_symmetry = $generator->symmetry_randomized(
    corpus_seed   => 7,
    symmetry_seed => 123456790,
);
is $different_symmetry->canonical_id, $generated->canonical_id,
    'same corpus seed with different symmetry seed keeps canonical record';
isnt $different_symmetry->transform_shorthand, $generated->transform_shorthand,
    'different symmetry seed records a different transform';

my $master_only = $generator->symmetry_randomized(
    corpus_seed   => 1,
    symmetry_seed => 42,
    criteria      => { difficulty => 'Master' },
);
is $master_only->canonical_id, '17C-000002',
    'criteria constrain canonical seed selection';

my $query_only = $generator->symmetry_randomized(
    corpus_seed   => 99,
    symmetry_seed => 42,
    query         => $corpus->select(difficulty => 'Easy'),
);
is $query_only->canonical_id, '17C-000001',
    'query object can constrain canonical seed selection';

my $hash = $generated->as_hash;
is $hash->{puzzle}, $generated->puzzle, 'as_hash includes generated puzzle';
is $hash->{solution}, $generated->solution,
    'as_hash includes transformed solution';
is $hash->{provenance}{canonical_id}, $generated->canonical_id,
    'as_hash includes canonical ID provenance';
is $hash->{provenance}{symmetry_transform}, $generated->transform_shorthand,
    'as_hash includes explicit transform provenance';

for my $case (
    [ sub { Sudoku::Generator->new(corpus => 'bad') }, qr/corpus must be/, 'invalid corpus is rejected' ],
    [ sub { $generator->symmetry_randomized(symmetry_seed => 1) }, qr/corpus_seed is required/, 'missing corpus seed is rejected' ],
    [ sub { $generator->symmetry_randomized(corpus_seed => 'x', symmetry_seed => 1) }, qr/corpus_seed must be an integer seed/, 'invalid corpus seed is rejected' ],
    [ sub { $generator->symmetry_randomized(corpus_seed => 1, symmetry_seed => []) }, qr/symmetry_seed must be an integer seed/, 'invalid symmetry seed is rejected' ],
    [ sub { $generator->symmetry_randomized(corpus_seed => 1, symmetry_seed => 1, criteria => []) }, qr/criteria must be a hash reference/, 'invalid criteria are rejected' ],
    [ sub { $generator->symmetry_randomized(corpus_seed => 1, symmetry_seed => 1, query => []) }, qr/query must be/, 'invalid query is rejected' ],
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
        clue_count => 9,
        canonicalization => {
            scheme         => 'SudokuSolver',
            scheme_version => '1.0',
        },
        difficulty => {
            scheme           => 'SudokuSolver',
            scheme_version   => '2.7',
            score            => $args{score},
            label            => $args{label},
            highest_strategy => 'Hidden Singles',
        },
        pattern_symmetries => [],
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $args{puzzle},
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}

sub _fixture_solution {
    my ($puzzle) = @_;
    $puzzle =~ s/0/1/g;
    return $puzzle;
}
