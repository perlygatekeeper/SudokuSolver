#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Deduction;
use Sudoku::Render::Text;

{
package Local::Difficulty;

sub new {
    my ($class, %args) = @_;

    return bless {
        label          => $args{label}          // 'Unrated',
        rating_version => $args{rating_version} // '1.0',
    }, $class;
}

sub label {
    my ($self) = @_;
    return $self->{label};
}

sub rating_version {
    my ($self) = @_;
    return $self->{rating_version};
}

}

{
package Local::Solver;

sub new {
    my ($class, %args) = @_;

    return bless {
        contradiction  => $args{contradiction},
        deduction_count => $args{deduction_count} // 0,
        difficulty      => $args{difficulty}
            // Local::Difficulty->new,
    }, $class;
}

sub has_contradiction {
    my ($self) = @_;
    return defined $self->{contradiction};
}

sub contradiction {
    my ($self) = @_;
    return $self->{contradiction};
}

sub deduction_count {
    my ($self) = @_;
    return $self->{deduction_count};
}

sub difficulty {
    my ($self) = @_;
    return $self->{difficulty};
}

}

{
package Local::Contradiction;

sub new {
    my ($class, %args) = @_;

    return bless {
        summary => $args{summary}
            // 'zero_candidates Cell has no remaining candidates R4C7',
    }, $class;
}

sub summary {
    my ($self) = @_;
    return $self->{summary};
}

}

my $renderer = Sudoku::Render::Text->new;

my $mode_renderer = Sudoku::Render::Text->new(
mode => 'quiet',
);

is(
$mode_renderer->mode,
'quiet',
'renderer accepts an explicit output mode',
);

$mode_renderer->mode('trace');

is(
$mode_renderer->mode,
'trace',
'renderer mode can be updated',
);

like(
$renderer->pass_start(3),
qr/^Pass 3/m,
'renderer formats pass start',
);

like(
$renderer->strategy_result('Naked Singles', 0),
qr/Naked Singles: no deductions/,
'renderer formats no-deduction strategy result',
);

like(
$renderer->strategy_result('Hidden Singles', 1),
qr/Hidden Singles: applied 1 deduction/,
'renderer formats one-deduction strategy result',
);

like(
$renderer->strategy_result('Naked Pairs', 2),
qr/Naked Pairs: applied 2 deductions/,
'renderer pluralizes multiple deductions',
);

like(
$renderer->restart_notice,
qr/Restarting from Naked Singles/,
'renderer formats restart notice',
);

like(
$renderer->pass_end(3, 1),
qr/End Pass 3: applied 1 deduction/,
'renderer formats a successful pass ending',
);

like(
$renderer->pass_end(4, 0),
qr/End Pass 4: no progress/,
'renderer formats a stalled pass ending',
);

is(
$renderer->debug_grid_header(12),
"Grid after deduction 12:\n",
'renderer labels debug grids by deduction number',
);

my $grid = Grid->new;
$grid->load_from_string('0' x 81);

my $hidden_cell = $grid->cell_from_row_column(8, 1);

my $hidden = Sudoku::Deduction->new(
strategy    => 'Hidden Singles',
action      => 'set_value',
cell        => $hidden_cell,
value       => 6,
unit_type   => 'box',
unit_index  => 6,
reason      => 'Candidate 6 appears only once in Box 7.',
explanation => 'R9C2 must be 6.',
);

my $hidden_text = $renderer->deduction($hidden);

like(
$hidden_text,
qr/Hidden Single in Box 7:/,
'renderer includes the box number for a hidden single',
);

like(
$hidden_text,
qr/Set R9C2 = 6/,
'renderer formats a set-value deduction',
);

like(
$hidden_text,
qr/Why: Candidate 6 appears only once in Box 7./,
'renderer includes the logical reason',
);

like(
$hidden_text,
qr/Detail: R9C2 must be 6./,
'renderer includes nonduplicate detail',
);

my $removal = Sudoku::Deduction->new(
strategy    => 'Pointing / Claiming',
action      => 'remove_candidate',
cell        => $grid->cell_from_row_column(3, 7),
value       => 5,
reason      => 'Candidate 5 is confined to row 4 inside Box 6.',
explanation => 'Remove candidate 5 from R4C8.',
);

my $removal_text = $renderer->deduction($removal);

like(
$removal_text,
qr{Pointing / Claiming:},
'renderer formats the strategy title',
);

like(
$removal_text,
qr/Remove candidate 5 from R4C8/,
'renderer formats candidate removal',
);

like(
$removal_text,
qr/Why: Candidate 5 is confined to row 4 inside Box 6./,
'renderer preserves the candidate-removal reason',
);

like(
$removal_text,
qr/Detail: Remove candidate 5 from R4C8./,
'renderer includes distinct candidate-removal detail',
);

my $duplicate_explanation = Sudoku::Deduction->new(
strategy    => 'Naked Singles',
action      => 'set_value',
cell        => $grid->cell_from_row_column(0, 0),
value       => 9,
reason      => 'Only one candidate remains.',
explanation => 'Only one candidate remains.',
);

my $duplicate_text = $renderer->deduction($duplicate_explanation);

unlike(
$duplicate_text,
qr/Detail:/,
'renderer does not repeat identical reason and detail text',
);

my $solution =
'123456789'
. '456789123'
. '789123456'
. '214365897'
. '365897214'
. '897214365'
. '531642978'
. '642978531'
. '978531642';

my $solved_grid = Grid->new;
$solved_grid->load_from_string($solution);

my $solved_solver = Local::Solver->new(
deduction_count => 64,
difficulty      => Local::Difficulty->new(
label          => 'Hard',
rating_version => '1.0',
),
);

my $solved_status = $renderer->final_status(
$solved_solver,
$solved_grid,
);

like(
$solved_status,
qr/^Solved$/m,
'renderer labels a completed puzzle as solved',
);

like(
$solved_status,
qr/Solved all 81 cells in 64 deductions./,
'renderer reports the solved deduction count',
);

like(
$solved_status,
qr/Difficulty: Hard \(method v1.0\)/,
'renderer reports solved-puzzle difficulty and method version',
);

like(
$solved_status,
qr/Solution: \Q$solution\E/,
'renderer includes the final solution string',
);

my $stalled_grid = Grid->new;
$stalled_grid->load_from_string(
'000000010'
. '400000000'
. '020000000'
. '000050407'
. '008000300'
. '001090000'
. '300400200'
. '050100000'
. '000806000'
);

my $stalled_solver = Local::Solver->new(
deduction_count => 17,
difficulty      => Local::Difficulty->new(
label          => 'Medium',
rating_version => '1.0',
),
);

my $stalled_status = $renderer->final_status(
$stalled_solver,
$stalled_grid,
);

like(
$stalled_status,
qr/^Stalled$/m,
'renderer labels an incomplete puzzle as stalled',
);

like(
$stalled_status,
qr{Solved cells: \d+ / 81},
'renderer reports solved-cell progress',
);

like(
$stalled_status,
qr/Remaining cells: \d+/,
'renderer reports remaining cells',
);

like(
$stalled_status,
qr/Deductions applied: 17/,
'renderer reports deductions applied before stalling',
);

like(
$stalled_status,
qr/Difficulty so far: Medium \(method v1.0\)/,
'renderer reports provisional difficulty for a stalled puzzle',
);

like(
$stalled_status,
qr/No registered strategy can make further progress./,
'renderer explains why solving stopped',
);

my $contradiction_solver = Local::Solver->new(
contradiction => Local::Contradiction->new(
summary => 'zero_candidates Cell has no remaining candidates R4C7',
),
deduction_count => 23,
difficulty      => Local::Difficulty->new(
label          => 'Expert',
rating_version => '1.0',
),
);

my $contradiction_status = $renderer->final_status(
$contradiction_solver,
$stalled_grid,
);

like(
$contradiction_status,
qr/^Contradiction$/m,
'renderer labels a contradictory puzzle state',
);

like(
$contradiction_status,
qr/zero_candidates Cell has no remaining candidates R4C7/,
'renderer includes the contradiction summary',
);

like(
$contradiction_status,
qr/Deductions applied: 23/,
'renderer reports deductions applied before the contradiction',
);

like(
$contradiction_status,
qr/Difficulty so far: Expert \(method v1.0\)/,
'renderer reports provisional difficulty for a contradiction',
);

done_testing();

