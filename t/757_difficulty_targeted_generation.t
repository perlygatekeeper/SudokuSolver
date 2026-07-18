use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku ();
use Sudoku::Corpus;
use Sudoku::Generator;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');

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

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
print {$out} JSON::PP->new->canonical(1)->encode(_record($puzzle, $solution)), "\n";
close $out;

my $generator = Sudoku::Generator->new(
    corpus => Sudoku::Corpus->new(file => $master),
);

my $generated = $generator->difficulty_targeted(
    corpus_seed       => 1,
    symmetry_seed     => 1,
    reveal_seed       => 1,
    clue_count        => 17,
    difficulty        => 'Easy',
    score             => { min => 2, max => 2 },
    highest_strategy  => 'Hidden Singles',
    strategy_ceiling  => 'Hidden Singles',
    generation_date   => '2026-07-17T00:00:00Z',
);

isa_ok $generated, 'Sudoku::GeneratedPuzzle';
is $generated->difficulty_label, 'Easy',
    'difficulty-targeted generation records accepted difficulty label';
is $generated->difficulty_score, 2,
    'difficulty-targeted generation records accepted difficulty score';
is $generated->highest_strategy, 'Hidden Singles',
    'difficulty-targeted generation records accepted highest strategy';
is $generated->difficulty_rating_version, '2.7',
    'difficulty-targeted generation records rating method version';
is $generated->generation_attempts, 1,
    'accepted candidate records generation attempt count';
is $generated->generator_version, $Sudoku::VERSION,
    'generated puzzle records generator version';
is $generated->generation_date, '2026-07-17T00:00:00Z',
    'generated puzzle preserves supplied generation date';
like $generated->coordinate_encoding, qr/\A(?:[1-9]*-){8}[1-9]*\z/,
    'generated puzzle exposes final coordinate encoding';

my $hash = $generated->as_hash;
is $hash->{difficulty}{rating_version}, '2.7',
    'as_hash includes difficulty rating version';
is $hash->{provenance}{generation_attempts}, 1,
    'as_hash includes generation attempt count';
is $hash->{provenance}{generator_version}, $Sudoku::VERSION,
    'as_hash includes generator version';
is $hash->{provenance}{coordinate_encoding}, $generated->coordinate_encoding,
    'as_hash includes generated puzzle coordinate encoding';

my $label_set = $generator->difficulty_targeted(
    corpus_seed      => 1,
    symmetry_seed    => 1,
    reveal_seed      => 1,
    clue_count       => 17,
    difficulty_label => [ 'Easy', 'Medium' ],
    difficulty_score => { gte => 2, lte => 2 },
    strategy_ceiling => 2,
);
is $label_set->difficulty_label, 'Easy',
    'difficulty target accepts label sets and numeric strategy ceiling';

my $prefilter_master = File::Spec->catfile($tmpdir, 'prefilter-master.jsonl');
open my $prefilter_out, '>:raw', $prefilter_master
    or die "Cannot create '$prefilter_master': $!";
print {$prefilter_out} JSON::PP->new->canonical(1)->encode(
    _record(
        $puzzle,
        $solution,
        canonical_id     => '17C-000001',
        fingerprint      => 'fp-low',
        difficulty_score => 1,
        difficulty_label => 'Trivial',
        highest_strategy => 'Naked Singles',
    ),
), "\n";
print {$prefilter_out} JSON::PP->new->canonical(1)->encode(
    _record(
        $puzzle,
        $solution,
        canonical_id     => '17C-000002',
        fingerprint      => 'fp-high',
        difficulty_score => 2,
        difficulty_label => 'Easy',
        highest_strategy => 'Hidden Singles',
    ),
), "\n";
close $prefilter_out;

my $prefilter_corpus = Sudoku::Corpus->new(file => $prefilter_master);
is(
    $prefilter_corpus->select->random(seed => 2, limit => 1)->first->{identity}{canonical_id},
    '17C-000001',
    'seeded corpus selection would choose the lower-rated record before prefiltering',
);

my $prefiltered_generator = Sudoku::Generator->new(corpus => $prefilter_corpus);
my $prefiltered = $prefiltered_generator->difficulty_targeted(
    corpus_seed      => 2,
    symmetry_seed    => 1,
    reveal_seed      => 1,
    clue_count       => 17,
    difficulty       => 'Easy',
    strategy_ceiling => 'Hidden Singles',
);

is $prefiltered->canonical_id, '17C-000002',
    'difficulty-targeted generation starts from an already eligible base puzzle';

for my $case (
    [ sub { $generator->difficulty_targeted(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 17, difficulty => 'Master', max_attempts => 1) }, qr/No corpus records satisfy the base difficulty prefilter/, 'difficulty target with no eligible base records is rejected' ],
    [ sub { $generator->difficulty_targeted(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 17, strategy_ceiling => 'Naked Singles', max_attempts => 1) }, qr/No generated puzzle matched/, 'too-low strategy ceiling is rejected' ],
    [ sub { $generator->difficulty_targeted(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 17, strategy_ceiling => 'Unknown Strategy', max_attempts => 1) }, qr/Unknown strategy ceiling/, 'unknown strategy ceiling is rejected' ],
    [ sub { $generator->difficulty_targeted(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 17, max_attempts => 0) }, qr/max_attempts must be/, 'invalid max attempts is rejected' ],
) {
    my ($callback, $pattern, $name) = @{$case};
    my $ok = eval { $callback->(); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name with useful error";
}

done_testing();

sub _record {
    my ($puzzle, $solution, %overrides) = @_;

    my $canonical_id = $overrides{canonical_id} // '17C-000001';
    my $fingerprint = $overrides{fingerprint} // 'fp-001';
    my $difficulty_score = $overrides{difficulty_score} // 2;
    my $difficulty_label = $overrides{difficulty_label} // 'Easy';
    my $highest_strategy = $overrides{highest_strategy} // 'Hidden Singles';

    return {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => $canonical_id,
            fingerprint      => $fingerprint,
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
            score            => $difficulty_score,
            label            => $difficulty_label,
            highest_strategy => $highest_strategy,
        },
        pattern_symmetries => [],
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $puzzle,
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}
