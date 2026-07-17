use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku::Corpus;
use Sudoku::Generator;

my $tmpdir = tempdir(CLEANUP => 1);
my $master = File::Spec->catfile($tmpdir, 'master.jsonl');
my $artifact = File::Spec->catfile($tmpdir, 'generated.json');

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
    corpus_seed      => 1,
    symmetry_seed    => 1,
    reveal_seed      => 9,
    clue_count       => 20,
    difficulty       => 'Easy',
    strategy_ceiling => 'Hidden Singles',
    generation_date  => '2026-07-17T00:00:00Z',
);

my $json = $generated->as_json;
like $json, qr/"puzzle"/, 'generated puzzle serializes as readable JSON';
like $json, qr/"generation_date" : "2026-07-17T00:00:00Z"/,
    'serialized provenance includes generation date';
like $json, qr/"coordinate_encoding"/,
    'serialized provenance includes coordinate encoding';
like $json, qr/"difficulty"/,
    'serialized artifact includes versioned difficulty metadata';

is $generated->write_file($artifact), $artifact,
    'generated puzzle writes a replay artifact';
ok -s $artifact, 'replay artifact exists on disk';

my $from_data = $generator->replay(data => $generated->as_hash);
is $from_data->puzzle, $generated->puzzle,
    'replay from hash reproduces exact generated puzzle';
is $from_data->solution, $generated->solution,
    'replay from hash reproduces transformed solution';
is_deeply $from_data->reveal_cells, $generated->reveal_cells,
    'replay from hash preserves explicit reveal list';
is $from_data->coordinate_encoding, $generated->coordinate_encoding,
    'replay from hash verifies coordinate encoding';
is $from_data->difficulty_rating_version, $generated->difficulty_rating_version,
    'replay preserves difficulty rating version';

my $from_file = $generator->replay(file => $artifact);
is $from_file->puzzle, $generated->puzzle,
    'replay from file reproduces exact generated puzzle';
is $from_file->base_puzzle, $generated->base_puzzle,
    'replay from file reconstructs the transformed pre-reveal puzzle';

my $bad_puzzle = $generated->as_hash;
substr($bad_puzzle->{puzzle}, 0, 1) =
    substr($bad_puzzle->{puzzle}, 0, 1) eq '0' ? '1' : '0';
my $bad_puzzle_ok = eval { $generator->replay(data => $bad_puzzle); 1 };
ok !$bad_puzzle_ok, 'replay rejects a stored puzzle that does not match provenance';
like $@, qr/replayed puzzle does not match/,
    'bad stored puzzle reports a useful replay error';

my $bad_coordinate = $generated->as_hash;
$bad_coordinate->{provenance}{coordinate_encoding} = 'bad';
my $bad_coordinate_ok = eval { $generator->replay(data => $bad_coordinate); 1 };
ok !$bad_coordinate_ok, 'replay rejects a bad coordinate encoding';
like $@, qr/coordinate encoding/,
    'bad coordinate encoding reports a useful replay error';

my $bad_difficulty = $generated->as_hash;
$bad_difficulty->{difficulty}{label} = 'Master';
my $bad_difficulty_ok = eval { $generator->replay(data => $bad_difficulty); 1 };
ok !$bad_difficulty_ok, 'replay rejects mismatched difficulty metadata';
like $@, qr/stored difficulty label/,
    'bad difficulty metadata reports a useful replay error';

done_testing();

sub _record {
    my ($puzzle, $solution) = @_;

    return {
        schema => {
            name    => 'SudokuSolver canonical corpus',
            version => '1.0',
        },
        identity => {
            canonical_id     => '17C-000001',
            fingerprint      => 'fp-001',
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
            score            => 2,
            label            => 'Easy',
            highest_strategy => 'Hidden Singles',
        },
        pattern_symmetries => [],
        provenance => {
            source_ordinal    => 1,
            source_puzzle     => $puzzle,
            witness_transform => 'D=123456789;B=012;R=012|012|012;S=012;C=012|012|012',
        },
    };
}
