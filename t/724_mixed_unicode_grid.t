#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';
use Sudoku::Render::GridCharacters;
use Sudoku::Render::Text;

{ package Local::Cell; sub new { bless { value=>$_[1] }, $_[0] } sub value { $_[0]{value} } sub given { 0 } }
{ package Local::Grid; sub new { bless { cells=>[Local::Cell->new(1), map { Local::Cell->new(0) } 1..80] }, $_[0] } sub cells { $_[0]{cells} } }

ok(grep { $_ eq 'UNICODE_MIXED' } Sudoku::Render::GridCharacters->names, 'mixed character set is discoverable');
my $set = Sudoku::Render::GridCharacters->character_set('UNICODE_MIXED');
is($set->{horizontal}, '━', 'mixed set uses heavy major horizontal');
is($set->{horizontal_minor}, '─', 'mixed set uses light minor horizontal');
is($set->{vertical}, '┃', 'mixed set uses heavy major vertical');
is($set->{vertical_minor}, '│', 'mixed set uses light minor vertical');
my $text = Sudoku::Render::Text->new(character_set=>'UNICODE_MIXED')->pretty_grid(Local::Grid->new);
like($text, qr/┏━━━┯━━━┯━━━┳.*┳.*┓/, 'top border mixes heavy and light junctions');
like($text, qr/┠───┼───┼───╂.*╂.*┨/, 'minor row uses light rules through heavy box boundaries');
like($text, qr/┣━━━┿━━━┿━━━╋.*╋.*┫/, 'major row uses heavy rules through light cell boundaries');
done_testing;
