use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;
use Test::More;

use lib 'lib';
use Sudoku::CoordinateEncoding qw(clue_count);
use Sudoku::Corpus;
use Sudoku::Generator;

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
);

open my $out, '>:raw', $master or die "Cannot create '$master': $!";
my $json = JSON::PP->new->canonical(1);
print {$out} $json->encode($_), "\n" for @records;
close $out;

my $generator = Sudoku::Generator->new(
    corpus => Sudoku::Corpus->new(file => $master),
);

my $generated = $generator->controlled_reveals(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
    reveal_seed   => 24680,
    clue_count    => 13,
);

isa_ok $generated, 'Sudoku::GeneratedPuzzle';
is $generated->base_clue_count, 10,
    'controlled reveals preserve the transformed base clue count';
is $generated->clue_count, 13,
    'controlled reveals reach the exact requested clue count';
is $generated->target_clue_count, 13,
    'generated puzzle records the requested target clue count';
is $generated->reveal_seed, 24680,
    'generated puzzle records reveal seed separately';
is scalar @{ $generated->reveal_cells }, 3,
    'generated puzzle records one reveal cell per added clue';
like $generated->reveal_cells->[0], qr/\AR[1-9]C[1-9]\z/,
    'reveal cells are stored as explicit row-column labels';
isnt $generated->puzzle, $generated->base_puzzle,
    'final puzzle differs from the transformed base puzzle after reveals';
is $generated->transformed_puzzle, $generated->base_puzzle,
    'transformed_puzzle aliases the pre-reveal puzzle';

for my $index (0 .. 80) {
    my $base_clue = substr($generated->base_puzzle, $index, 1);
    next if $base_clue eq '0';
    is substr($generated->puzzle, $index, 1), $base_clue,
        'controlled reveals do not remove or change original transformed clues';
}

is _replay_reveals(
    $generated->base_puzzle,
    $generated->solution,
    @{ $generated->reveal_cells },
), $generated->puzzle,
    'explicit reveal-cell list replays the final puzzle';

my $same = $generator->controlled_reveals(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
    reveal_seed   => 24680,
    clue_count    => 13,
);
is_deeply $same->reveal_cells, $generated->reveal_cells,
    'same reveal seed records the same reveal cells';
is $same->puzzle, $generated->puzzle,
    'same seeds produce the same revealed puzzle';

my $different_reveals = $generator->controlled_reveals(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
    reveal_seed   => 24681,
    clue_count    => 13,
);
is $different_reveals->base_puzzle, $generated->base_puzzle,
    'changing only the reveal seed preserves the transformed base puzzle';
isnt join(',', @{ $different_reveals->reveal_cells }),
    join(',', @{ $generated->reveal_cells }),
    'different reveal seed records a different reveal list';
isnt $different_reveals->puzzle, $generated->puzzle,
    'different reveal seed can produce a different final puzzle';

my $no_extra_clues = $generator->controlled_reveals(
    corpus_seed   => 7,
    symmetry_seed => 123456789,
    reveal_seed   => 24680,
    clue_count    => 10,
);
is $no_extra_clues->puzzle, $no_extra_clues->base_puzzle,
    'requesting the base clue count adds no reveals';
is_deeply $no_extra_clues->reveal_cells, [],
    'no-op controlled reveal stores an empty reveal list';

my $hash = $generated->as_hash;
is $hash->{puzzle}, $generated->puzzle,
    'as_hash exposes final revealed puzzle';
is $hash->{base_puzzle}, $generated->base_puzzle,
    'as_hash exposes pre-reveal transformed puzzle when it differs';
is $hash->{provenance}{reveal_seed}, $generated->reveal_seed,
    'as_hash includes reveal seed provenance';
is_deeply $hash->{provenance}{reveal_cells}, $generated->reveal_cells,
    'as_hash includes explicit reveal-cell provenance';
is $hash->{provenance}{final_clue_count}, 13,
    'as_hash includes final clue count provenance';

for my $case (
    [ sub { $generator->controlled_reveals(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1) }, qr/clue_count is required/, 'missing clue count is rejected' ],
    [ sub { $generator->controlled_reveals(corpus_seed => 1, symmetry_seed => 1, clue_count => 13) }, qr/reveal_seed is required/, 'missing reveal seed is rejected' ],
    [ sub { $generator->controlled_reveals(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 'many') }, qr/clue_count must be/, 'invalid clue count is rejected' ],
    [ sub { $generator->controlled_reveals(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 82) }, qr/clue_count must be/, 'too-large clue count is rejected' ],
    [ sub { $generator->controlled_reveals(corpus_seed => 1, symmetry_seed => 1, reveal_seed => 1, clue_count => 9) }, qr/cannot be less than/, 'target below current clue count is rejected' ],
) {
    my ($callback, $pattern, $name) = @{$case};
    my $ok = eval { $callback->(); 1 };
    ok !$ok, $name;
    like $@, $pattern, "$name with useful error";
}

done_testing();

sub _replay_reveals {
    my ($puzzle, $solution, @labels) = @_;

    my @cells = split //, $puzzle;
    for my $label (@labels) {
        my ($row, $column) = $label =~ /\AR([1-9])C([1-9])\z/;
        die "Bad reveal label '$label'" unless defined $row;
        my $index = ($row - 1) * 9 + ($column - 1);
        $cells[$index] = substr($solution, $index, 1);
    }

    return join q{}, @cells;
}

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
