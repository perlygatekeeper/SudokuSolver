#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use lib 'lib';

use Grid;
use Sudoku::Deduction;
use Sudoku::Render::Text;

my $renderer = Sudoku::Render::Text->new;

my $mode_renderer = Sudoku::Render::Text->new(mode => 'quiet');
is($mode_renderer->mode, 'quiet', 'renderer accepts an explicit output mode');
$mode_renderer->mode('trace');
is($mode_renderer->mode, 'trace', 'renderer mode can be updated');

like($renderer->pass_start(3), qr/^Pass 3/m, 'renderer formats pass start');
like($renderer->strategy_result('Naked Singles', 0), qr/Naked Singles: no deductions/, 'renderer formats no-deduction strategy result');
like($renderer->strategy_result('Hidden Singles', 1), qr/Hidden Singles: applied 1 deduction/, 'renderer formats one deduction strategy result');
like($renderer->restart_notice, qr/Restarting from Naked Singles/, 'renderer formats restart notice');

my $grid = Grid->new;
$grid->load_from_string('0' x 81);
my $cell = $grid->cell_from_row_column(8, 1);

my $hidden = Sudoku::Deduction->new(
    strategy    => 'Hidden Singles',
    action      => 'set_value',
    cell        => $cell,
    value       => 6,
    reason      => 'Hidden in Box  ',
    explanation => 'Candidate 6 appears only once in this box.',
);

my $hidden_text = $renderer->deduction($hidden);
like($hidden_text, qr/Hidden Single in Box 7:/, 'renderer includes box number for hidden single in a box');
like($hidden_text, qr/Set R9C2 = 6/, 'renderer formats set-value deduction');
like($hidden_text, qr/Reason: Candidate 6 appears only once/, 'renderer includes explanation');

my $removal = Sudoku::Deduction->new(
    strategy    => 'Pointing / Claiming',
    action      => 'remove_candidate',
    cell        => $grid->cell_from_row_column(3, 7),
    value       => 5,
    explanation => 'Candidate 5 is confined to row 4 inside box 6.',
);

my $removal_text = $renderer->deduction($removal);
like($removal_text, qr/Pointing \/ Claiming:/, 'renderer formats strategy title');
like($removal_text, qr/Remove candidate 5 from R4C8/, 'renderer formats candidate removal');

my $solution = '123456789456789123789123456214365897365897214897214365531642978642978531978531642';
my $solved = Grid->new;
$solved->load_from_string($solution);
like($renderer->final_status(bless({ }, 'Local::NoContradiction'), $solved), qr/Final solution is:/, 'renderer formats solved final status');

{
    package Local::NoContradiction;
    sub has_contradiction { return 0 }
}

done_testing();
